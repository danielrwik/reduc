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
repeated -- if a routine crashes or is CTL-C'ed,
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

If there are point source(s) in the FOV,
make exclude region called `excl.reg` and
place it in the `event_cl` directory.
Emission from galaxy clusters
does not vary, so this step can be skipped (be sure to remove the `/excl`
keyword below in that case).
However, it can still be useful to remove the brightest regions even
if the emission shouldn't vary with time, so that lower level variability
won't be swamped by a high source rate.

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
Any bright source area should be included in the region(s) listed.
If the source covers the entire FOV, or is likely to bleed over into
the background regions given the size of the exclusion region, that
source emission will need to be included as a model during the `XSpec`
fitting, otherwise it will be confused for a background component and
lead to the background being overestimated.

***Manual Steps***

First, create instrument maps and sky-projected background maps for
later use (if you decide to extract new background regions, these steps
do not need to be rerun -- only if the CALDB is updated in some important
way will these products ever need to be remade).

    dir='50310000_M33'
    obsid='50310001002'
    imname='im4to25keV.fits'
    cldir=dir+'/'+obsid+'/event_cl/'
    bdname='bgd'
    base='bgdbox'
    savfile='bgdnames.sav'

    bgddir=cldir+bdname+'/'
    if not file_test(bgddir,/directory) then spawn,'mkdir '+bgddir

    ab=['A','B']
    for iab=0,n_elements(ab)-1 do begin & $
        nuskybgd_instrmap,dir,obsid,ab[iab],bdname  & $
        fits_read,cldir+imname,blah,header  & $
        projinitbgds,dir,obsid,header,ab[iab],bdname  & $
    endfor

Next, make background regions.
Follow the `nuskybgd` guide for creating the region files.
Also following the guide for the `nuskybgd_fitab` step, list your
region filenames in the IDL variable `regnames`.
If you are lazy or want to create an initial set of regions to adjust, run:

    mkbgdregs,cldir,dir+'/srcexcl.reg',base,regnames=regnames,acceptfrac=0.1

Still following the `nuskybgd` guide, you can extract background spectra using
these regions with `nuproducts`.
For later steps, you also want to define variables in `IDL` to let the code
know what the names of the spectra are and whether the region/spectrum is from
the A or B telescope.
For example, the region names from the `mkbgdregs` routine will be called
'bgdboxA1.reg', etc., and if the spectral files are similarly named
'bgdboxA1.pha', the following code will make the needed variables `abarr`
and `spec`.
Alternatively, you can just set them manually, e.g.,
`IDL> spec=['bgdboxA1.pha','bgdboxA2.pha',...]` and `IDL> spec=['A','A',...]`.

    undefine,abarr,spec
    for i=0,n_elements(regnames)-1 do begin & $
        if strpos(regnames[i],'A') ne -1 then push,abarr,'A' else push,abarr,'B' & $
        blah=strsplit(regnames[i],'.',/extract) & $
        push,spec,blah[0]+'.pha' & $
    endfor

Instead of running `nuproducts`, there is an option to create spectra directly
in `IDL`, which has the added benefit of applying detector absorption to the
response files (which has to be done after the rmf files are created with
`nuproducts`) and the spectra are grouped to at least 3 counts per bin, which
would also need to be applied to `nuproducts` spectra if grouping was not
specified in the call to that routine.

    for iab=0,n_elements(ab)-1 do begin & $
        ii=where(abarr eq ab[iab]) & $
        getspecrmf,cldir+'nu'+obsid+ab[iab]+'01_cl.evt',ab[iab],cldir+regnames[ii],$
              bgddir,bgddir,base,/cmprmf & $
    endfor

Lastly, save some of these variables in case a crash occurs in `IDL` and their
values are lost.

    ab='AB'
    save,filename=cldir+savfile,regnames,spec,base,bgddir,cldir,ab


***Automated Steps***

Automated version of above steps; main difference is that regions are
created automatically, which should be fine in cases where the target
doesn't extend over the majority of the FOV, but could lead to less
ideal results.

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
