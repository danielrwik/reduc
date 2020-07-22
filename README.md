# IDL scripts to facilitate NuSTAR data processing

### Purpose

This step-by-step ABC-like guide is meant to allow the user to process a
*NuSTAR* dataset so that it is ready for the creation of Level 3 data
products (via `nuproducts` and/or other custom `IDL` analysis suites,
such as [NuCrossARF](https://github.com/danielrwik/nucrossarf) or
`NuImylze` [in development]).
There are two primary steps:
1) light curve filtering and reprocessing and
2) background characterization.

This cookbook is meant to automate as much of the processing as possible,
which means things can go horribly wrong **IF YOU DO NOT GRASP WHAT IS
HAPPENING AT EVERY STAGE**.  In particular, the `nuskybgd` routines (what's
largely contained within `mkbgdstuff.pro`) should ideally be run by hand on a
simple dataset first so that you know what it does and how it might go wrong.

### Dependencies

Required routines are located in the
[NuSkyBGD GitHub repository](https://github.com/NuSTAR/nuskybgd)
and consist mostly of `IDL` routines (requiring `AstroLib` routines) as
well as some simple python scripts.
In addtion, you will need some of the routines found in the
[NuUtils GitHub repository](https://github.com/danielrwik/nuutils),
*and* you will need to add the file `spechdr.txt` from the `auxil`
directory of that distribution to your `NUSKYBGD_AUXIL` directory.
As outlined in the `nuskybgd` installation instructions, your `IDL`
path should include all `\*.pro` files from these distributions.

> DISCLAIMER:
> There may be additional necessary routines I have failed to include.
> In this case,
> you'll see an error saying the routine (or it may think the routine is a
> variable) is not defined.  There is nothing you can do.  
> You must obtain the routine.
> The only way to do so it ask me for it.
> Otherwise you are doomed.
> You and your entire family.  For all time.  Until time ends.
> Then you all will be fine again.  For what that's worth.

### ABC Guide

I assume `IDL` is running in a directory above where data is stored.
For example, sets of observations are often grouped together inside
a directory, where each observation has its own directory named after
its OBSID.
If all your data are stored in `data/`, and all M33 data (which we used
here as an example) is stored in `50310000_M33/`,
your path to the cleaned event data would be
`/blah/bloo/data/50310000_M33/50310001002/event_cl`.

To begin:

    prompt> cd /blah/bloo/data
    prompt> idl
    IDL> (below commands)

The following commands are meant to be copy-and-pasted into the `IDL`
command line, so some definitions (like dir='..') are
epeated -- if a routine crashes or is CTL-C'ed,
`IDL` wipes variable names so it's convenient to not have to scroll
up to reinitialize parameters.

    dir='50310000_M33'
    obsid='50310001002'
    imname='im4to25keV.fits'


#### Make initial images

The combined image can be used to define exclusion region(s)
in `ds9` so bright source variability doesn't contaminate
the low energy light curve.

    cldir=dir+'/'+obsid+'/event_cl/'
    mkimgs,cldir,obsid,'A',4,25
    mkimgs,cldir,obsid,'B',4,25
    fits_read,cldir+'imA4to25keV.fits',im1,h
    fits_read,cldir+'imB4to25keV.fits',im2
    im=im1+im2
    fits_write,cldir+imname,im1+im2,h


#### GTI filtering

Filter out periods (in 100s chunks) where the background is high,
either due to SAA enhancement (using the hard band 50-160 keV) or
solar activity (using the soft band 1.6-20 keV).

If point source(s) in FOV, make exclude region called `excl.reg` and
place it in the `event_cl` directory.  Emission from galaxy clusters
does not vary, so this step can be skipped (be sure to remove `/excl`
keyword below in that case).

    tbin=100.

    lcfilter,dir,obsid,'A',50,160,imname,tbin
    lcfilter,dir,obsid,'A',50,160,imname,tbin,/usr
    lcfilter,dir,obsid,'A',1.6,20,imname,tbin,/usr,/excl
    lcfilter,dir,obsid,'B',50,160,imname,tbin
    lcfilter,dir,obsid,'B',50,160,imname,tbin,/usr
    lcfilter,dir,obsid,'B',1.6,20,imname,tbin,/usr,/excl


#### Reprocess data using new GTI files

This script moves `event_cl` to `event_defcl` and runs `nupipeline`
excluding the bad GTIs found during `lcfilter`.

    reproc,dir,obsid


#### Remake images


    dir='50310000_M33'
    obsid='50310001002'
    imname='im4to25keV.fits'

    cldir=dir+'/'+obsid+'/event_cl/'
    mkimgs,cldir,obsid,'A',4,25
    mkimgs,cldir,obsid,'B',4,25
    fits_read,cldir+'imA4to25keV.fits',im1,h
    fits_read,cldir+'imB4to25keV.fits',im2
    im=im1+im2
    fits_write,cldir+imname,im1+im2,h


#### Create BGD Files & Fit

Need to make `dir+'/srcexcl.reg'` to exclude non-modeled features.

    bdname='bgd'
    base='bgdbox'
    savfile='bgdnames.sav'

    mkbgdstuff,dir,obsid,'AB',imname,bdname,base,regnames,spec,savfile


#### Fit BGD

    dir='50310000_M33'
    obsid='50310001002'
    savfile='bgdnames.sav'
    cldir=dir+'/'+obsid+'/event_cl/'
    bdname='bgd'
    base='bgdbox'
    savfile='bgdnames.sav'

    nofit=1
    fixfcxb=1
    fixap=1
    restore,cldir+savfile

    nuskybgd_fitab,dir,obsid,regnames,bdname,spec,'AB',bdname,$
          nofit=nofit,fixfcxb=fixfcxb,fixap=fixap

    XSPEC12> statistic cstat
    XSPEC12> setpl reb 20 30
    XSPEC12> setpl comm res y 3e-5 0.01
    XSPEC12> thaw apbgd:3,15
    XSPEC12> pl ld ra
    XSPEC12> fit 100
    XSPEC12> pl ld ra
    XSPEC12> thaw fcxb:3,6,9,12
    XSPEC12> fit
    XSPEC12> @50310000_M33/50310001002/event_cl/bgd/bgdparams.xcm


#### Make BGD-subtracted image

    dir='50310000_M33'
    obsid='50310001002'
    cldir=dir+'/'+obsid+'/event_cl/'
    ab=['A','B']
    imname='im4to25keV.fits'
    savfile='bgdnames.sav'
    restore,cldir+savfile
    bdname='bgd'
    for iab=0,1 do $
          nuskybgd_image,dir,obsid,'im'+ab[iab]+'4to25keV.fits',4,25,ab[iab],$
                bdname,bdname,/noremakeinstr
    fits_read,cldir+'im4to25keV.fits',im,h
    fits_read,cldir+'bgdimA4to25keV.fits',im1
    fits_read,cldir+'bgdimB4to25keV.fits',im2
    fits_write,cldir+'im4to25keVbsub.fits',im-(im1+im2),h
