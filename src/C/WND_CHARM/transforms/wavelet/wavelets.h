#ifndef _WAVELETS_H_
#define _WAVELETS_H_

#include <stdlib.h>

#define wtmalloc(size_t) malloc(size_t)
#define wtcalloc(len, size_t) calloc(len, size_t)
#define wtfree(ptr) free(ptr)


enum TRANSFORM_TYPE {
	   TRANSFORM_TYPE_INVALID = -1,
	   DWT,
	   IDWT,
	   SWT,
       RECONSTRUCTION,
	   TRANSFORM_TYPE_MAX
};

enum SYMMETRY {
	UNKNOWN = -1,
	ASYMMETRIC = 0,
	NEAR_SYMMETRIC = 1,
	SYMMETRIC = 2
};

typedef struct {const double* dec_hi;		// highpass decomposition
				const double* dec_lo;		// lowpass	decomposition
				const double* rec_hi;		// highpass reconstruction
				const double* rec_lo;		// lowpass	reconstruction
				
				int dec_len;	// length of decomposition filter
				int rec_len;	// length of reconstruction filter
				
				int dec_hi_offset;		// usually 0, but some filters are shifted in time
				int dec_lo_offset;
				int rec_hi_offset;		// - || -
				int rec_lo_offset;		// - || -

				int vanishing_moments_psi;
				int vanishing_moments_phi;
				int support_width;

				int symmetry:3;

				int orthogonal:1;
				int biorthogonal:1;
				int orthonormal:1;

				int compact_support:1;

				int _builtin:1;

				char* family_name;
				char* short_name;
} Wavelet;

Wavelet* wavelet(char name, int type);
Wavelet* blank_wavelet(int filters_length);

void free_wavelet(Wavelet *wavelet);

#endif

