static char rcsid[] = "$Header$";

#include <simple.h>

swap_long(p)
register char *p;
{
    char t;

    SWAP(p[0], p[3], t);
    SWAP(p[1], p[2], t);
}

swap_short(p)
register char *p;
{
    char t;

    SWAP(p[0], p[1], t);
}
