/* --- Copyright University of Sussex 1993. All rights reserved. ----------
 * File:            $popvision/lib/float_byte.c
 * Purpose:         Convert between float and byte arrays
 * Author:          David S Young, Jun 11 1992 (see revisions)
 * Related Files:   float_byte.p
 */

void float_to_byte (inimage, instart, outimage, outstart, n, p0, p255)

float           *inimage;
int              instart;
unsigned char   *outimage;
int              outstart;
int              n;
float            p0;
float            p255;

{
    float           *inpoint, *inend;
    unsigned char   *outpoint;
    float            inval, c;

    if (p0 == 0.0 && p255 == 255.0)

        for (inpoint    =   inimage + instart,
             inend      =   inpoint + n - 1,
             outpoint   =   outimage + outstart;

             inpoint <= inend;

             inpoint++,     outpoint++) {

                inval = *inpoint + 0.5;
                if (inval < 0.0) inval = 0.0;
                if (inval > 255.0) inval = 255.0;
                *outpoint = inval;
            }

    else {

        c = 255.0 / (p255 - p0);

        for (inpoint    =   inimage + instart,
             inend      =   inpoint + n - 1,
             outpoint   =   outimage + outstart;

             inpoint <= inend;

             inpoint++,     outpoint++) {

                inval = c * (*inpoint - p0) + 0.5;
                if (inval < 0.0) inval = 0.0;
                if (inval > 255.0) inval = 255.0;
                *outpoint = inval;
            }

        }

}

void byte_to_float (inimage, instart, outimage, outstart, n, p0, p255)

unsigned char   *inimage;
int              instart;
float           *outimage;
int              outstart;
int              n;
float            p0;
float            p255;

{
    unsigned char   *inpoint, *inend;
    float           *outpoint;
    float            inval, c;

    if (p0 == 0.0 && p255 == 255.0)

        for (inpoint    =   inimage + instart,
             inend      =   inpoint + n - 1,
             outpoint   =   outimage + outstart;

             inpoint <= inend;

             inpoint++,     outpoint++) {

                *outpoint = *inpoint;
            }

    else {

        c = (p255 - p0) / 255.0;

        for (inpoint    =   inimage + instart,
             inend      =   inpoint + n - 1,
             outpoint   =   outimage + outstart;

             inpoint <= inend;

             inpoint++,     outpoint++) {

                *outpoint = c * (float)*inpoint + p0;  /* cast added */
            }

        }

}

/* --- Revision History ---------------------------------------------------
--- David S Young, Nov  5 1993
        Cast added where marked to avoid warning about ANSI C semantics
 */
