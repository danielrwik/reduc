pro mkbgdstuff,indir,inobsid,inab,inimname,inbdname,inbase,regnames,spec,savfile

dir=indir
obsid=inobsid
ab=inab
imname=inimname
bdname=inbdname
base=inbase

if ab eq 'AB' then ab=['A','B']

cldir=dir+'/'+obsid+'/event_cl/'
bgddir=cldir+bdname+'/'


;if not file_test(cldir+'bad'+bdname,/directory) and $
;      file_test(bgddir,/directory) then $
;      spawn,'mv '+cldir+bdname+' '+cldir+'bad'+bdname
for iab=0,n_elements(ab)-1 do begin
    if not file_test(bgddir,/directory) then spawn,'mkdir '+bgddir
    nuskybgd_instrmap,dir,obsid,ab[iab],bdname
    if not file_test(cldir+imname) then $
          stop,'MKBGDSTUFF: '+cldir+imname+' does not exist'
    fits_read,cldir+imname,blah,header
    projinitbgds,dir,obsid,header,ab[iab],bdname
endfor

if not file_test(dir+'/srcexcl.reg') then $
      stop,'MKBGDSTUFF: Warning, '+dir+'/srcexcl.reg not provided, entire obs used'
mkbgdregs,cldir,dir+'/srcexcl.reg',base,regnames=regnames,acceptfrac=0.1

undefine,abarr,spec
for i=0,n_elements(regnames)-1 do begin
    if strpos(regnames[i],'A') ne -1 then push,abarr,'A' else push,abarr,'B'
    blah=strsplit(regnames[i],'.',/extract)
    push,spec,blah[0]+'.pha'
endfor



if 1 then begin

print,cldir
print,'  '+abarr
for iab=0,n_elements(ab)-1 do begin
    ii=where(abarr eq ab[iab])
    getspecrmf,cldir+'nu'+obsid+ab[iab]+'01_cl.evt',ab[iab],cldir+regnames[ii],$
          bgddir,bgddir,base,/cmprmf
endfor

endif

save,filename=cldir+savfile,regnames,spec,base,bgddir,cldir,ab

end
