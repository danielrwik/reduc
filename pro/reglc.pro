pro reglc,cldir,obsid,regfile,abstr,e1in,e2in,imfile,tbin=tbin,mindt=mindt,$
      usr=usr

if size(regfile,/type) eq 7 then mask=reg2mask(imfile,regfile) else $
       if size(regfile,/type) eq 0 then begin
           mask=intarr(1000,1000)
           mask[*,*]=1
       endif else if size(regfile,/type) eq 2 then mask=regfile else $
             stop,'REGFILE is unacceptable.'
if size(e1in,/type) eq 0 then begin
    e1=(3.-1.6)/0.04
    e2=(25.-1.6)/0.04
endif else begin
    e1=(e1in-1.6)/0.04
    e2=(e2in-1.6)/0.04
endelse
if not keyword_set(mindt) then mindt=100.
if keyword_set(usr) then usr='usr' else usr=''

undefine,t1
undefine,t2
t0=fltarr(n_elements(obsid))
nt=fltarr(n_elements(obsid))
for ep=0,n_elements(obsid)-1 do begin
  for iab=0,n_elements(abstr)-1 do begin
    if usr eq 'usr' then begin
        gtifile=cldir[ep]+'/nu'+obsid[ep]+abstr[iab]+'01_'+usr+'gti.fits'
        extno=1
    endif else begin
        gtifile=cldir[ep]+'/nu'+obsid[ep]+abstr[iab]+'01_cl.evt'
        extno=2
    endelse
    gti=mrdfits(gtifile,extno,eh,/silent)
    if iab eq 0 then begin
        gti1=gti.start
        gti2=gti.stop
        tt1=gti1
        tt2=gti2
        t0[ep]=sxpar(eh,'TSTART')
    endif else begin
        undefine,tt1
        undefine,tt2
        for i=0,n_elements(gti)-1 do begin
            minval=min(abs(gti1-gti[i].start),ii)
            if minval lt mindt then begin
                if gti1[ii] gt gti[i].start then push,tt1,gti1[ii] $
                  else push,tt1,gti[i].start
                minval=min(abs(gti2-gti[i].stop),ii)
                if gti2[ii] lt gti[i].stop then push,tt2,gti2[ii] $
                  else push,tt2,gti[i].stop
            endif
        endfor
    endelse
  endfor
  ii=where(tt2-tt1 gt mindt)
  tt1=tt1[ii]
  tt2=tt2[ii]
  nt[ep]=n_elements(tt1)
  push,t1,tt1
  push,t2,tt2 
endfor

if keyword_set(tbin) then begin
    undefine,newt1,newt2
    for ep=0,n_elements(obsid)-1 do begin
        cnt=0
        for i=0,nt[ep]-1 do begin
            if ep eq 0 then ntep=0 else for e=0,ep-1 do ntep+=nt[e]
            nbin=floor((t2[i]-t1[i])/tbin)
            if nbin le 1 then begin
                push,newt1,t1[i+ntep]
                push,newt2,t2[i+ntep]
                cnt++
            endif else begin
                dt=(t2[i]-t1[i])/nbin
                for j=0,nbin-1 do begin
                    push,newt1,t1[i+ntep]+j*dt
                    push,newt2,t1[i+ntep]+(j+1)*dt
                    cnt++
                endfor
            endelse
        endfor
        nt[ep]=cnt
    endfor
    t1=newt1
    t2=newt2
endif

rate=fltarr(n_elements(t1))
for ep=0,n_elements(obsid)-1 do for iab=0,n_elements(abstr)-1 do begin
    evts=mrdfits(cldir[ep]+'/nu'+obsid[ep]+$
          abstr[iab]+'01_cl.evt',1,eh,/silent)
    ii=where(mask[evts.x-1,evts.y-1] gt 0.5 and evts.pi ge e1 and evts.pi lt e2)
    for i=0,n_elements(t1)-1 do begin
        jj=where(evts[ii].time ge t1[i] and evts[ii].time lt t2[i])
        if jj[0] ne -1 then rate[i]+=n_elements(jj)
    endfor
endfor
err=sqrt(rate)/(t2-t1)
rate=rate/(t2-t1)
;rate/=2.
;err/=2.
prevnt=0
for ep=0,n_elements(obsid)-1 do begin
    ii=indgen(nt[ep])+prevnt
    t1[ii]-=t0[ep]
    t2[ii]-=t0[ep]
    prevnt+=nt[ep]
endfor

;t1/=3600.*24.
;t2/=3600.*24.
col=intarr(n_elements(t1))
col[0:nt[0]-1]=1
;if n_elements(nt) ge 2 then col[nt[0]:nt[0]+nt[1]-1]=2
;if n_elements(nt) ge 3 then col[nt[0]+nt[1]:nt[0]+nt[1]+nt[2]-1]=4

yrasave=[-0.1,max(rate)+max(err)]
xrasave=[0,max(t2/3600./24.)]
yra=yrasave
xra=xrasave
xdata=(t1+t2)/2./3600./24.
ydata=rate

;print,'When asked to click, click twice (one time each at the lower,'
;print,'   then upper, ends of range) and then click outside the box'
;print,' z = zoom (2 clicks)'
;print,' f = return to full range'
;print,' x = exclude/include nearest point (continues until e)'
;print,' e = exit and save'
undefine,excl1,excl2,incl1,incl2
yesno='n'
todo='&'
while strmid(yesno,0,1) ne 'y' do begin

plot,[0],/nodata,xra=xra,/xst,yra=yra,/yst
for i=0,n_elements(t1)-1 do begin
    oplot,[t1[i],t2[i]]/3600./24.,rate[i]+[0.,0.],color=col[i]
    oplot,(t1[i]+t2[i])/2./3600./24.+[0.,0.],rate[i]+err[i]*[-1.,1.],color=col[i]
endfor

if todo ne 'x' and todo ne '&' then todo=get_kbrd()
if todo eq 'z' then begin
    print,' zoomin! click twice'
    clickn,x,y,2
    print,'New x range = ',x
    print,'New y range = ',y
    xra=x
    yra=y
endif else if todo eq 'f' then begin
    print,' zoomin back out'
    xra=xrasave
    yra=yrasave
endif else if todo eq 'r' then begin
    print,'click on either side of include/exclude x range'
    clickn,x,y,2
    if x[1] lt x[0] then begin
        blah=x[0]
        x[0]=x[1]
        x[1]=blah
    endif
    ii=where(xdata ge x[0] and xdata le x[1])
    if ii[0] ne -1 then begin
        if total(col[ii]) le n_elements(ii)*1.5 then newcol=2 else newcol=1
        col[ii]=newcol
    endif
endif else if todo eq 'x' then begin
    print,'to end, click y lt 0'
    clickn,x,y,1
    if y gt 0. then begin
        blah=min((xdata-x[0])^2+(ydata-y[0])^2,ipt)
        print,'Point switched: ',xdata[ipt],ydata[ipt]
        if col[ipt] eq 1 then col[ipt]=2 else col[ipt]=1
    endif else todo='b'
endif else if todo eq 'e' then yesno='y' else begin
    if todo ne '&' then print,'unrecognized command, trying again:' $
          else todo='b'
    print,' z = zoom (2 clicks)'
    print,' f = return to full range'
    print,' x = exclude/include nearest point (continues until e)'
    print,' r = exclude/include range (2 clicks)'
    print,' e = exit and save'
endelse

;undefine,x,y
;clicker,x,y,/noprint
;todo=''
;;read,todo,prompt='Exclude (x), Include (i), Abandon (a)? '
;print,'Exclude (x), Include (i), Abandon (a)? '
;todo=get_kbrd()
;if strmid(todo,0,1) eq 'x' or strmid(todo,0,1) eq 'i' then begin
;    if strmid(todo,0,1) eq 'x' then begin
;        push,excl1,x[0]*3600.*24.
;        push,excl2,x[1]*3600.*24.
;    endif else begin
;        push,incl1,x[0]*3600.*24.
;        push,incl2,x[1]*3600.*24.
;    endelse
;endif
;;read,yesno,prompt='Finished? '
;print,'Finished? (y/n) '
;yesno=get_kbrd()
;
;isdefined=size(excl1,/type)
;if isdefined ne 0 then for i=0,n_elements(excl1)-1 do begin
;    ii=where((t1+t2)/2. gt excl1[i] and (t1+t2)/2. lt excl2[i])
;    if ii[0] ne -1 then col[ii]=2
;endfor
;isdefined=size(incl1,/type)
;if isdefined ne 0 then for i=0,n_elements(incl1)-1 do begin
;    ii=where((t1+t2)/2. gt incl1[i] and (t1+t2)/2. lt incl2[i])
;    if ii[0] ne -1 then col[ii]=1
;endfor
;
;plot,[0],/nodata,xra=[0,max(t2/3600./24.)],/xst,yra=[0,max(rate)+max(err)],/yst
;for i=0,n_elements(t1)-1 do begin
;    oplot,[t1[i],t2[i]]/3600./24.,rate[i]+[0.,0.],color=col[i]
;    oplot,(t1[i]+t2[i])/2./3600./24.+[0.,0.],rate[i]+err[i]*[-1.,1.],color=col[i]
;endfor


endwhile

ii=where(col eq 2)
if ii[0] ne -1 then begin
    undefine,newt1,newt2
;    push,newt1,t1[ii[0]]+t0[0]
;    if n_elements(ii) ge 2 then for i=1,n_elements(ii)-1 do $
;          if ii[i]-ii[i-1] gt 1 then begin
;        push,newt2,t2[ii[i-1]]+t0[0]
;        push,newt1,t1[ii[i]]+t0[0]
;    endif
;    push,newt2,t2[ii[n_elements(ii)-1]]+t0[0]
    newt1=t1[ii]+t0[0]
    newt2=t2[ii]+t0[0]

    if usr eq 'usr' then begin
        gtifile=cldir[0]+'/nu'+obsid[0]+abstr[0]+'01_'+usr+'gti.fits'
        extno=1
    endif else begin
        gtifile=cldir[0]+'/nu'+obsid[0]+abstr[0]+'01_cl.evt'
        extno=2
    endelse
    gti=mrdfits(gtifile,extno,eh,/silent)
    g1=gti.start
    g2=gti.stop
;    ii=where(newt1 lt g1[0])
;    if ii[0] ne -1 then begin
;        imax=max(ii)
;        newt1=newt1[imax:n_elements(newt1)-1]
;        newt1[imax]=g1[0]
;        newt2=newt2[imax:n_elements(newt1)-1]
;    endif
;    ii=where(newt2 gt g2[n_elements(g2)-1])
;    if ii[0] ne -1 then begin
;        imin=min(ii)
;        newt1=newt1[0:imin]
;        newt2=newt2[0:imin]
;        newt2[imin]=g2[0]
;    endif

    for j=0,n_elements(newt1)-1 do begin
        i=0
        while i le n_elements(g1)-1 do begin
            if g1[i] lt newt2[j] and g1[i] ge newt1[j] and $
                    g2[i] gt newt2[j] then g1[i]=newt2[j] $
              else if g2[i] gt newt1[j] and g2[i] le newt2[j] and $
                    g1[i] lt newt1[j] then g2[i]=newt1[j] $
              else if g1[i] lt newt1[j] and g2[i] gt newt2[j] then begin
                  temp=g2[i]
                  g2[i]=newt1[j]
                if i ne n_elements(g1)-1 then begin
                  g1=[g1[0:i],newt2[j],g1[i+1:n_elements(g1)-1]]
                  g2=[g2[0:i],temp,g2[i+1:n_elements(g2)-1]]
                endif else begin
                  g1=[g1[0:i],newt2[j]]
                  g2=[g2[0:i],temp]
                endelse
              endif else if newt1[j] le g1[i] and newt2[j] ge g2[i] then begin
                if i ne 0 and i ne n_elements(g1)-1 then begin
                  g1=[g1[0:i-1],g1[i+1:n_elements(g1)-1]]
                  g2=[g2[0:i-1],g2[i+1:n_elements(g2)-1]]
                endif else if i eq 0 then begin
                  g1=g1[1:n_elements(g1)-1]
                  g2=g2[1:n_elements(g2)-1]
                endif else begin
                  g1=g1[0:i-1]
                  g2=g2[0:i-1]
                  i--
                endelse
              endif   ;else stop,'case not handled'
            if g1[i] lt newt2[j] and g1[i] ge newt1[j] and $
                    g2[i] gt newt2[j] then print,1 $
            else if g2[i] gt newt1[j] and g2[i] le newt2[j] and $ 
                    g1[i] lt newt1[j] then print,2 $
            else if g1[i] lt newt1[j] and g2[i] gt newt2[j] then print,3 $
            else if newt1[j] le g1[i] and newt2[j] ge g2[i] then print,4
            i++
        endwhile
    endfor
    newgti=replicate({START:0.D, STOP:0.D},n_elements(g1))
    newgti.start=g1
    newgti.stop=g2
    sxaddpar,h,'NAXIS2',n_elements(g1)
    mwrfits,newgti,cldir+'/nu'+obsid+abstr+'01_usrgti.fits',eh,/silent,/create

    print
    print,'Original Expsoure reduced from '+ $
           str(total(gti.stop-gti.start)/1000.,format='(F5.1)')+' ks to '+$
           str(total(newgti.stop-newgti.start)/1000.,format='(F5.1)')+' ks'
    print
endif


end
