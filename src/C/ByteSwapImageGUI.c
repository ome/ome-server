/*
 * ByteSwapImage: Swap DeltaVision header and data to and from
 * native byte order
 *
 * Jim Newberry: May 2, 2000
 * Copyright 2000, Applied Precision, Inc.
 *
 * Frederick Myers: June, 2000 -- Added GUI code
 */

#include <stdlib.h>
#include <sys/param.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <libgen.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <errno.h>
#ifdef __linux__
#include <byteswap.h>
#endif

#include "IWInclude.h"
#include "WMInclude.h"
#include "AWRunUtils.h"
#include "Utility.h"
#define APP_NAME        "Image Byte Swapper"

#define DVID -16224

enum { FILE_IN, FILE_OUT };

static char         gcFiles[FILE_OUT + 1][IW_FILE_NAME_SIZE];

static Widget       gwStatusBar             = (Widget) NULL;
static Widget       gwExec                  = (Widget) NULL;
static int          giPercDone              = 0;
static int          giFile1OK               = 0;
static int          giFile2OK               = 0;
static int          giNumFiles              = -1;
static int          giCurFile               = 0;

static void         cancel_reset(void);

#define MY_FREE(s,type) \
    if((s) != (type)NULL) { free((s)); (s) = (type)NULL; }

static
int     update_percentage(const int iDone, const int iNumSections)
{
  int iResult = 0;


  if(giNumFiles != -1)
    iResult = 100 * ((float)giCurFile / (float)giNumFiles);
  else
    iResult = 100 * ( (float)iDone / (float)iNumSections ); 

  return(iResult > 100 ? 100 : iResult);
}


/*
   status if a given path points to a directory or not
*/
static
int     is_directory(const char *sPath)
{
  struct stat buf;

  stat(sPath, &buf);

  return(S_ISDIR(buf.st_mode));
}



/*
   extract the path from a given path string
*/
static
char *  extract_path(const char *sSrc, char *sDest)
{
  if(is_directory(sSrc))
  {
    strcpy(sDest, sSrc);
  }
  else
  {
    char *p = basename((char *)sSrc);
    int i;

    if(p - sSrc == 0)
      return(NULL);

    /* need better error checking for this... */
    for(i = 0; i < (int)(p - sSrc); i++)
      *(sDest + i) = *(sSrc + i);

    *(sDest + i) = '\0';

    if(*(sDest + strlen(sDest)) != '/')
      strcat(sDest, "/");

  }

  return(&sDest[0]);
}

static
int                 file_exists(const char *sPath)
{
  struct stat dummy;

  if(stat(sPath, &dummy) == -1)
  {
    errno = 0;
    return(0);
  }
  else
  {
    return(1);
  }
}


static
unsigned int       file_size(const char *sPath)
{
  struct stat buf;

  stat(sPath, &buf);

  return(buf.st_size);
}


/*
   set the enable/disable state of the do-it button depending on
   the validity of the user's input file and output directory
*/
static
void    set_doit_state(void)
{
  if(giFile1OK != 0 && giFile2OK != 0)
    WMEnableField(gwExec);
  else
    WMDisableField(gwExec);
}


/*
   logical equallity of 2 paths
*/
static
int     same_path(const char *sPath1, const char *sPath2)
{
  char p1[256], p2[256];

  if(*sPath1 == '\0' || *sPath2 == '\0')
    return(0);  

  realpath(sPath1, p1);
  realpath(sPath2, p2);

  return(strcmp(p1, p2) == 0);
}


/*
 * Swap two-byte entities
 */
static
void swap2(char *ptr, int ntimes)
{
#ifdef __linux__
    unsigned short *uptr = (unsigned short *)ptr;
    int i;
    
    for(i=0; i<ntimes; i++, uptr++)
    {
        *uptr = bswap_16(*uptr);
    }
#else
	char holder;
	int  i;
	
	for(i=0; i<ntimes*2; i+=2)
	{
		holder   = ptr[i];
		ptr[i]   = ptr[i+1];
		ptr[i+1] = holder;
	}
#endif
}

/*
 * Swap 4-byte entities appropriately between
 * Intel and Mac/SGI Unix. Does not correctly
 * swap VAX floating point values
 */
static
void swap4(char *ptr, int ntimes)
{
#ifdef __linux__
    unsigned long *lptr = (unsigned long *)ptr;
    int i;
    
    for(i=0; i<ntimes; i++, lptr++)
    {
        *lptr = bswap_32(*lptr);
    }
#else
	char holder;
	int  i;
	
	for(i=0; i<ntimes*4; i+=4)
	{
		holder   = ptr[i];
		ptr[i]   = ptr[i+3];
		ptr[i+3] = holder;
		
		holder   = ptr[i+1];
		ptr[i+1] = ptr[i+2];
		ptr[i+2] = holder;
	}
#endif
}

/*
 * Main
 */
static
int swap(const char *sInputFile, const char *sOutputFile)
{
	FILE *in_fp;
	FILE *out_fp;
	short *sptr;
	int *iptr;
	char *ptr;
	char the_header[1024];
	int data_type;
	int num_sections;
    int ext_hdr_size;
	int sec_size;
	int *ibuf = (int *) NULL;
	int nx, ny;
	int input_native = 0;
	int ndone;
	short *sbuf = (short *) NULL;
	char *cbuf = (char *) NULL;
	char *ext_hdr;



    errno = 0;

	/*
	 * Open input and output streams
	 */
	if((in_fp = fopen(sInputFile, "r")) == (FILE *)NULL)
      return(1);
	


    /*
       toss out files that are too small to even contain the proper header
    */
    if(file_size(sInputFile) < 1024)
      return(0);

	/*
	* Read header
	*/
	if(fread((void *)the_header, 1, 1024, in_fp) != 1024)
	{
		fclose(in_fp);
        return(0);
	}

	/*
	 * First determine if this is a foreign->native
	 * or native->foreign conversion
	 */
	sptr = (short *)(&the_header[96]);
	
	input_native = (*sptr == DVID);

	/*
	 * if input is native byte order, gather size
	 * info before the swap
	 */
	if(input_native)
	{
		/*
		 * Image data type
		 */
		iptr = (int *)(&the_header[12]);
		data_type = *iptr;

		/*
		 * Number of sections
		 */
		iptr = (int *)(&the_header[8]);
		num_sections = *iptr;

		/*
		 * number of X and Y
		 */
		iptr = (int *)(&the_header[0]);
		nx = *iptr;
		iptr = (int *)(&the_header[4]);
		ny = *iptr;
        
        /*
         * Extended header size (floats and ints, all 4-byte)
         */
        iptr = (int *)(&the_header[92]);
        ext_hdr_size = *iptr;
	}
	
	/*
	 * Swap appropriate parts of the header
	 */
	ptr = &the_header[0];
	swap4(ptr, 24);
	
	ptr = &the_header[96];
	swap2(ptr, 2);
	
	ptr = &the_header[128];
	swap2(ptr, 4);
	
	ptr = &the_header[136];
	swap4(ptr, 6);
    
    ptr = &the_header[160];
    swap2(ptr, 6);
    
    ptr = &the_header[172];
    swap4(ptr, 2);
    
    ptr = &the_header[180];
    swap2(ptr, 2);
    
    ptr = &the_header[184];
    swap4(ptr, 3);
            
	/*
	 * Handle the wavelength info
	 */
	
	ptr = &the_header[196];
	swap2(ptr, 6);
	
	
	ptr = &the_header[208];
	swap4(ptr, 4);
	
	/*
	 * if input is non-native, gather size info from
	 * swapped header
	 */
	if(!input_native)
	{
		/*
		 * Image data type
		 */
		iptr = (int *)(&the_header[12]);
		data_type = *iptr;

		/*
		 * Number of sections
		 */
		iptr = (int *)(&the_header[8]);
		num_sections = *iptr;

		/*
		 * number of X and Y
		 */
		iptr = (int *)(&the_header[0]);
		nx = *iptr;
		iptr = (int *)(&the_header[4]);
		ny = *iptr;
		
        /*
         * Extended header size (floats and ints, all 4-byte)
         */
        iptr = (int *)(&the_header[92]);
        ext_hdr_size = *iptr;
	}

    /*
       check for duplicate file
    */
    if(file_exists(sOutputFile))
    {
      char sMsg[512];

      sprintf(sMsg, "The output file %s already exists.\nOverwrite this file?", sOutputFile);

      switch(WMQuestion(sMsg, "Overwrite", "Keep"))
      {
        case 0: { return(-1);                   }       /* CANCEL   */
        case 1: { unlink(sOutputFile); break;   }       /* REPLACE  */
        case 2: { fclose(in_fp); return(0);     }       /* KEEP     */
      }
    }

    if(num_sections == 0)
    {
      printf("odd error condition -- num_sections == 0\n");
      fclose(in_fp);
      return(5);
    }

    if(file_size(sInputFile) < 1024 + ext_hdr_size)
    {
      fclose(in_fp);
      free(ext_hdr);
      return(4);
    }

   	if((out_fp = fopen(sOutputFile, "w")) == NULL)
	{
		fclose(in_fp);
        return(2);
	}
    
	fwrite(the_header, 1024, 1, out_fp);

	/*
	 * Extended header
	 */


	ext_hdr = (char *)malloc(ext_hdr_size);

    if(ext_hdr == (char *)NULL)
    {
      perror("calloc -- ext_hdr");
      return(-1);
    }

	fread(ext_hdr, ext_hdr_size, 1, in_fp);
	swap4(ext_hdr, ext_hdr_size/sizeof(float));

	fwrite(ext_hdr, ext_hdr_size, 1, out_fp);
	/*
	 * handle the data
	 */
	ndone = 0;

    sec_size = nx * ny;

	switch (data_type){
		case 1:
		case 3:
			sbuf = (short *)malloc(sec_size*sizeof(short));

            if(sbuf == NULL)
            {
              perror("malloc -- sbuf");
              return(-1);
            }

			while(fread(sbuf, sec_size*sizeof(short), 1, in_fp))
			{
				swap2((char *)(sbuf), sec_size);
				fwrite(sbuf, sec_size*sizeof(short), 1, out_fp);
				ndone++;
				if(ndone%5 == 0)
				{
                  giPercDone = update_percentage(ndone, num_sections);
                  WMUpdateField(gwStatusBar);
                  WMSync();
                }

			}
			free(sbuf);
            sbuf = NULL;
			break;
		case 2:
		case 4:
			ibuf = (int *)malloc(sec_size*sizeof(int));

            if(ibuf == NULL)
            {
              perror("malloc -- ibuf");
              return(-1);
            }

			while(fread(ibuf, sec_size*sizeof(int), 1, in_fp))
			{
				swap4((char *)ibuf, sec_size);
				fwrite(ibuf, sec_size*sizeof(int), 1, out_fp);
				ndone++;
				if(ndone%5 == 0)
				{
                  giPercDone = update_percentage(ndone, num_sections);
                  WMUpdateField(gwStatusBar);
                  WMSync();
				}
			}
			free(ibuf);
            ibuf = NULL;
			break;
		default:
		    cbuf = (char *)malloc(sec_size*sizeof(char));

            if(cbuf == NULL)
            {
              perror("malloc -- cbuf");
              return(-1);
            }

			while(fread(cbuf, sec_size*sizeof(char), 1, in_fp))
			{
				fwrite(cbuf, sec_size*sizeof(char), 1, out_fp);
				ndone++;
				if(ndone%5 == 0)
				{
                  giPercDone = update_percentage(ndone, num_sections);
                  WMUpdateField(gwStatusBar);
                  WMSync();
				}
			}
			free(cbuf);
            cbuf = NULL;
			break;
	}

    free(ext_hdr);

    ext_hdr = NULL;
	fclose(in_fp);
	fclose(out_fp);

  return(0);
}

static
void        cancel_reset(void)
{
  giPercDone  = 0;
  WMUpdateField(gwStatusBar);
  giCurFile = 0;
}


/*
   callback for scandir()
*/
#if defined(__linux__)
int             file_select(const struct dirent *entry)
#else
int             file_select(struct dirent *entry)
#endif
{
  /*
     just accept all non 'dot' files
  */
  return(*(entry->d_name) != '.');
}


static
void            display_error(const int iMsg)
{
  char sMsg[512];

  *sMsg  = '\0';

  switch(iMsg)
  {
    case 1: { strcpy(sMsg, "Could not open input file.");   break;      }
    case 2: { strcpy(sMsg, "Could not open output file.");  break;      }
    case 3: { strcpy(sMsg, "Could not read input header."); break;      }
    default: { break; }
  }

  if(*sMsg != '\0')
  {
    WMConfirmError(sMsg);
  }

}

static        
void     OnExec(void)
{

  char  sOutputFile[256];
  int   iResult;

  if(giFile1OK == 0)
  {
    WMConfirmError("A proper input file has not been chosen.");
    return;
  }

  if(giFile2OK == 0)
  {
    WMConfirmError("A proper output directory has not been chosen.");
    return;
  }


  if(is_directory(gcFiles[FILE_IN]))
  {
    /* batch mode */
    struct dirent **files;
    char    sInFile[256];
    int alphasort();

    giNumFiles =  scandir(gcFiles[FILE_IN], &files, file_select, alphasort);

    /* 
       iterate through the list of files and apply the swap
    */
    for(giCurFile = 0; giCurFile < giNumFiles; giCurFile++)
    {
      sprintf(sInFile, "%s/%s", gcFiles[FILE_IN], (*(files + giCurFile))->d_name);
      sprintf(sOutputFile, "%s/%s", gcFiles[FILE_OUT], (*(files + giCurFile))->d_name); 
      iResult = swap(sInFile, sOutputFile);

      if(iResult == -1)         /* cancel */
        break;
      else
        display_error(iResult);
    }
    printf("done...\n"); fflush( stdout );

  }
  else
  {
    sprintf(sOutputFile, "%s/%s", gcFiles[FILE_OUT], basename(gcFiles[FILE_IN]));
    iResult = swap(gcFiles[FILE_IN], sOutputFile);
    display_error(iResult);
  }

  cancel_reset();
  giNumFiles = -1;

}

static void     OnExit(void)
{
  exit(0);
}


static void     OnOpenInputFile(void)
{
  char dummy[256];

  giFile1OK = 0;

  if(same_path(extract_path(gcFiles[FILE_IN], dummy), gcFiles[FILE_OUT]))
  {
    WMConfirmError("The input directory must be different than the\nchosen output directory.");
    *gcFiles[FILE_IN] = '\0';
    set_doit_state();
    return;
  }

  giFile1OK = 1;

  set_doit_state();

}

static void     OnOpenOutputFile(void)
{
  char dummy[256];

  giFile2OK = 0;
  
  if(same_path(extract_path(gcFiles[FILE_IN], dummy), gcFiles[FILE_OUT]))
  {
    WMConfirmError("The output directory must be different than the\ndirectory for the input file.");
    *gcFiles[FILE_OUT] = '\0';
    set_doit_state();
    return;
  }

  giFile2OK = 1;
  set_doit_state();
}


int     main(int argc, char **argv)
{
  char *cTemp, cDirectory[IW_FILE_NAME_SIZE];

  if(IWAttach() == IW_ERROR)
  {
    fprintf(stderr, "softWoRx must be active for %s to run.\n", APP_NAME);
    exit(-1);
  }

  if((cTemp = IWGetConfig("DV_DATA")) == NULL)
  {
    getcwd(cDirectory, IW_FILE_NAME_SIZE);
  }
  else
  {
    strncpy(cDirectory, cTemp, IW_FILE_NAME_SIZE);
  }

  *(gcFiles[FILE_IN]) = '\0';
  *(gcFiles[FILE_OUT]) = '\0';

#ifdef AW
  WMSetResourceClassName("ArrayWoRx");
#endif
  WMInit(APP_NAME);
  WMAddGetFile("Input Image/Directory", cDirectory, NULL, IW_FILE_NAME_SIZE, 20, gcFiles[FILE_IN], 
                OnOpenInputFile, NULL, 0, 0);
  WMAttachRightSide();
  WMNewRow();

  WMAddGetFile("Output Directory", cDirectory, NULL, IW_FILE_NAME_SIZE, 20, gcFiles[FILE_OUT],
                OnOpenOutputFile, NULL, 0, 0);
  WMAttachRightSide();

  WMNewRow();
  WMAddSeparator();
  WMNewRow();

  gwStatusBar = WMAddStatusBar(NULL, 0, 100, &giPercDone, 0, 0);
  WMAttachRightSide();
  WMAddSeparator();
  WMAddDoneButton(NULL, OnExit, NULL, 0, 0x1);
  gwExec = WMAddFuncButton("  Do It  ", OnExec, NULL, 0, 0);
  set_doit_state();

  WMAddHelpButton(APP_NAME);

  WMDisplay();
	AWRunRegisterPgm("ByteSwapImageGUI", NULL, OnExit);
  WMAppMainLoop();
  exit(0);
}
