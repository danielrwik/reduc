pro mkbgdregs,cldir,exclreg,regbase,bgd=bgd,acceptfrac=acceptfrac,regnames=regnames

if size(regbase,/type) eq 0 then regbase='bgdbox'
if not keyword_set(acceptfrac) then acceptfrac=0.3
if not keyword_set(bgd) then bgd='bgd'
bgddir=cldir+'/'+bgd+'/'
xarr=intarr(1000,1000)
yarr=intarr(1000,1000)
for i=0,999 do begin
    xarr[i,*]=i
    yarr[*,i]=i
endfor
if size(exclreg,/type) ne 0 then begin
    srcmask=reg2mask(bgddir+'det0Aim.fits',exclreg)
    l=''
    openr,lun,exclreg,/get_lun
    undefine,blah
    while ~eof(lun) do begin
        readf,lun,l
        push,blah,l
    endwhile
    free_lun,lun
    ii=where(blah eq 'fk5')
;    if ii[0] eq -1 then ii=where(blah eq 'image')
;    if ii[0] eq -1 then ii=where(blah eq 'physical')
    if ii[0] eq -1 then stop,'MKBGDREGS: exclreg region file type unrecognized'
    bits=blah[ii[0]+1:n_elements(blah)-1]
endif else srcmask=intarr(1000,1000)
iisrc=where(srcmask gt 0.5)

ab=['A','B']
undefine,regnames
for iab=0,1 do begin
  cnt=1
  for i=0,3 do begin
    imname=bgddir+'det'+str(i)+ab[iab]+'im.fits'
    tregname=cldir+'temp'+ab[iab]+str(cnt)+'.reg'
    regname=regbase+ab[iab]+str(cnt)+'.reg'
    fits_read,imname,im,h
    pa=sxpar(h,'PA_PNT')+1.0
    x=total(xarr*im)/total(im)
    y=total(yarr*im)/total(im)
    xyad,h,x,y,ra,dec
    openw,lun,tregname,/get_lun
    printf,lun,'fk5'
    printf,lun,"box("+str(ra)+","+str(dec)+",6',6',"+str(pa)+')'
    free_lun,lun
    totreg=reg2mask(imname,tregname)
    spawn,'rm -f '+tregname
    reg=totreg
    reg[iisrc]=0
    if total(reg) gt total(totreg)*acceptfrac then begin
        openw,lun,cldir+regname,/get_lun
        printf,lun,'fk5'
        printf,lun,"box("+str(ra)+","+str(dec)+",6',6',"+str(pa)+')'
        for j=0,n_elements(bits)-1 do begin
            if strmid(bits[j],0,1) eq '-' then $
                  bits[j]=strmid(bits[j],1,strlen(bits[j]))
            openw,jlun,tregname,/get_lun
            printf,jlun,'fk5'
            printf,jlun,bits[j]
            free_lun,jlun
            mask=reg2mask(imname,tregname)
            if total(totreg*mask) gt 0 then printf,lun,'-'+bits[j]
            spawn,'rm -f '+tregname
        endfor
        free_lun,lun
        push,regnames,regname
        cnt++
    endif
  endfor
endfor

end
