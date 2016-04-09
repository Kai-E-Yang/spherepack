!
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!     *                                                               *
!     *                  copyright (c) 1998 by UCAR                   *
!     *                                                               *
!     *       University Corporation for Atmospheric Research         *
!     *                                                               *
!     *                      all rights reserved                      *
!     *                                                               *
!     *                      SPHEREPACK version 3.2                   *
!     *                                                               *
!     *       A Package of Fortran77 Subroutines and Programs         *
!     *                                                               *
!     *              for Modeling Geophysical Processes               *
!     *                                                               *
!     *                             by                                *
!     *                                                               *
!     *                  John Adams and Paul Swarztrauber             *
!     *                                                               *
!     *                             of                                *
!     *                                                               *
!     *         the National Center for Atmospheric Research          *
!     *                                                               *
!     *                Boulder, Colorado  (80307)  U.S.A.             *
!     *                                                               *
!     *                   which is sponsored by                       *
!     *                                                               *
!     *              the National Science Foundation                  *
!     *                                                               *
!     * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
!
!
! ... file shsgc.f
!
!     this file contains code and documentation for subroutines
!     shsgc and shsgci
!
! ... files which must be loaded with shsgc.f
!
!     sphcom.f, hrfft.f, gaqd.f
!
!     subroutine shsgc(nlat, nlon, isym, nt, g, idg, jdg, a, b, mdab, ndab, 
!    +                 wshsgc, lshsgc, work, lwork, ierror)
!
!     subroutine shsgc performs the spherical harmonic synthesis
!     on the arrays a and b and stores the result in the array g.
!     the synthesis is performed on an equally spaced longitude grid
!     and a gaussian colatitude grid.  the associated legendre functions
!     are recomputed rather than stored as they are in subroutine
!     shsgs.  the synthesis is described below at output parameter
!     g.
!
!     input parameters
!
!     nlat   the number of points in the gaussian colatitude grid on the
!            full sphere. these lie in the interval (0, pi) and are compu
!            in radians in theta(1), ..., theta(nlat) by subroutine gaqd.
!            if nlat is odd the equator will be included as the grid poi
!            theta((nlat+1)/2).  if nlat is even the equator will be
!            excluded as a grid point and will lie half way between
!            theta(nlat/2) and theta(nlat/2+1). nlat must be at least 3.
!            note: on the half sphere, the number of grid points in the
!            colatitudinal direction is nlat/2 if nlat is even or
!            (nlat+1)/2 if nlat is odd.
!
!     nlon   the number of distinct londitude points.  nlon determines
!            the grid increment in longitude as 2*pi/nlon. for example
!            nlon = 72 for a five degree grid. nlon must be greater
!            than or equal to 4. the efficiency of the computation is
!            improved when nlon is a product of small prime numbers.
!
!     isym   = 0  no symmetries exist about the equator. the synthesis
!                 is performed on the entire sphere.  i.e. on the
!                 array g(i, j) for i=1, ..., nlat and j=1, ..., nlon.
!                 (see description of g below)
!
!            = 1  g is antisymmetric about the equator. the synthesis
!                 is performed on the northern hemisphere only.  i.e.
!                 if nlat is odd the synthesis is performed on the
!                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
!                 if nlat is even the synthesis is performed on the
!                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
!
!
!            = 2  g is symmetric about the equator. the synthesis is
!                 performed on the northern hemisphere only.  i.e.
!                 if nlat is odd the synthesis is performed on the
!                 array g(i, j) for i=1, ..., (nlat+1)/2 and j=1, ..., nlon.
!                 if nlat is even the synthesis is performed on the
!                 array g(i, j) for i=1, ..., nlat/2 and j=1, ..., nlon.
!
!     nt     the number of syntheses.  in the program that calls shsgc, 
!            the arrays g, a and b can be three dimensional in which
!            case multiple synthesis will be performed.  the third
!            index is the synthesis index which assumes the values
!            k=1, ..., nt.  for a single synthesis set nt=1. the
!            discription of the remaining parameters is simplified
!            by assuming that nt=1 or that the arrays g, a and b
!            have only two dimensions.
!
!     idg    the first dimension of the array g as it appears in the
!            program that calls shsgc. if isym equals zero then idg
!            must be at least nlat.  if isym is nonzero then idg must
!            be at least nlat/2 if nlat is even or at least (nlat+1)/2
!            if nlat is odd.
!
!     jdg    the second dimension of the array g as it appears in the
!            program that calls shsgc. jdg must be at least nlon.
!
!     mdab   the first dimension of the arrays a and b as it appears
!            in the program that calls shsgc. mdab must be at least
!            min((nlon+2)/2, nlat) if nlon is even or at least
!            min((nlon+1)/2, nlat) if nlon is odd
!
!     ndab   the second dimension of the arrays a and b as it appears
!            in the program that calls shsgc. ndab must be at least nlat
!
!     a, b    two or three dimensional arrays (see the input parameter
!            nt) that contain the coefficients in the spherical harmonic
!            expansion of g(i, j) given below at the definition of the
!            output parameter g.  a(m, n) and b(m, n) are defined for
!            indices m=1, ..., mmax and n=m, ..., nlat where mmax is the
!            maximum (plus one) longitudinal wave number given by
!            mmax = min(nlat, (nlon+2)/2) if nlon is even or
!            mmax = min(nlat, (nlon+1)/2) if nlon is odd.
!
!     wshsgc an array which must be initialized by subroutine shsgci.
!            once initialized, wshsgc can be used repeatedly by shsgc
!            as long as nlat and nlon remain unchanged.  wshsgc must
!            not be altered between calls of shsgc.
!
!     lshsgc the dimension of the array wshsgc as it appears in the
!            program that calls shsgc. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            then lshsgc must be at least
!
!               nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15
!
!     work   a work array that does not have to be saved.
!
!     lwork  the dimension of the array work as it appears in the
!            program that calls shsgc. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            if isym is zero then lwork must be at least
!
!                      nlat*(nlon*nt+max(3*l2, nlon))
!
!            if isym is not zero then lwork must be at least
!
!                      l2*(nlon*nt+max(3*nlat, nlon))
!
!     **************************************************************
!
!     output parameters
!
!     g      a two or three dimensional array (see input parameter nt)
!            that contains the discrete function which is synthesized.
!            g(i, j) contains the value of the function at the gaussian
!            colatitude point theta(i) and longitude point
!            phi(j) = (j-1)*2*pi/nlon. the index ranges are defined
!            above at the input parameter isym.  for isym=0, g(i, j)
!            is given by the the equations listed below.  symmetric
!            versions are used when isym is greater than zero.
!
!     the normalized associated legendre functions are given by
!
!     pbar(m, n, theta) = sqrt((2*n+1)*factorial(n-m)/(2*factorial(n+m)))
!                       *sin(theta)**m/(2**n*factorial(n)) times the
!                       (n+m)th derivative of (x**2-1)**n with respect
!                       to x=cos(theta)
!
!
!     define the maximum (plus one) longitudinal wave number
!     as   mmax = min(nlat, (nlon+2)/2) if nlon is even or
!          mmax = min(nlat, (nlon+1)/2) if nlon is odd.
!
!     then g(i, j) = the sum from n=0 to n=nlat-1 of
!
!                   .5*pbar(0, n, theta(i))*a(1, n+1)
!
!              plus the sum from m=1 to m=mmax-1 of
!
!                   the sum from n=m to n=nlat-1 of
!
!              pbar(m, n, theta(i))*(a(m+1, n+1)*cos(m*phi(j))
!                                    -b(m+1, n+1)*sin(m*phi(j)))
!
!     ierror = 0  no errors
!            = 1  error in the specification of nlat
!            = 2  error in the specification of nlon
!            = 3  error in the specification of isym
!            = 4  error in the specification of nt
!            = 5  error in the specification of idg
!            = 6  error in the specification of jdg
!            = 7  error in the specification of mdab
!            = 8  error in the specification of ndab
!            = 9  error in the specification of lwshig
!            = 10 error in the specification of lwork
!
!
! ****************************************************************
!
!     subroutine shsgci(nlat, nlon, wshsgc, lshsgc, dwork, ldwork, ierror)
!
!     subroutine shsgci initializes the array wshsgc which can then
!     be used repeatedly by subroutines shsgc. it precomputes
!     and stores in wshsgc quantities such as gaussian weights, 
!     legendre polynomial coefficients, and fft trigonometric tables.
!
!     input parameters
!
!     nlat   the number of points in the gaussian colatitude grid on the
!            full sphere. these lie in the interval (0, pi) and are compu
!            in radians in theta(1), ..., theta(nlat) by subroutine gaqd.
!            if nlat is odd the equator will be included as the grid poi
!            theta((nlat+1)/2).  if nlat is even the equator will be
!            excluded as a grid point and will lie half way between
!            theta(nlat/2) and theta(nlat/2+1). nlat must be at least 3.
!            note: on the half sphere, the number of grid points in the
!            colatitudinal direction is nlat/2 if nlat is even or
!            (nlat+1)/2 if nlat is odd.
!
!     nlon   the number of distinct londitude points.  nlon determines
!            the grid increment in longitude as 2*pi/nlon. for example
!            nlon = 72 for a five degree grid. nlon must be greater
!            than or equal to 4. the efficiency of the computation is
!            improved when nlon is a product of small prime numbers.
!
!     wshsgc an array which must be initialized by subroutine shsgci.
!            once initialized, wshsgc can be used repeatedly by shsgc
!            as long as nlat and nlon remain unchanged.  wshsgc must
!            not be altered between calls of shsgc.
!
!     lshsgc the dimension of the array wshsgc as it appears in the
!            program that calls shsgc. define
!
!               l1 = min(nlat, (nlon+2)/2) if nlon is even or
!               l1 = min(nlat, (nlon+1)/2) if nlon is odd
!
!            and
!
!               l2 = nlat/2        if nlat is even or
!               l2 = (nlat+1)/2    if nlat is odd
!
!            then lshsgc must be at least
!
!                  nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15
!
!     dwork  a real work array that does not have to be saved.
!
!     ldwork the dimension of the array dwork as it appears in the
!            program that calls shsgci. ldwork must be at least
!
!                 nlat*(nlat+4)
!
!     output parameter
!
!     wshsgc an array which must be initialized before calling shsgc.
!            once initialized, wshsgc can be used repeatedly by shsgc
!            as long as nlat and nlon remain unchanged.  wshsgc must not
!            altered between calls of shsgc.
!
!     ierror = 0  no errors
!            = 1  error in the specification of nlat
!            = 2  error in the specification of nlon
!            = 3  error in the specification of lshsgc
!            = 4  error in the specification of ldwork
!            = 5  failure in gaqd to compute gaussian points
!                 (due to failure in eigenvalue routine)
!
!
! ****************************************************************
subroutine shsgc(nlat, nlon, mode, nt, g, idg, jdg, a, b, mdab, ndab, &
                    wshsgc, lshsgc, work, lwork, ierror)
!     subroutine shsgc performs the spherical harmonic synthesis on
!     a gaussian grid using the coefficients in array(s) a, b and returns
!     the results in array(s) g.  the legendre polynomials are computed
!     as needed in this version.
!
dimension g(idg, jdg, 1), a(mdab, ndab, 1), b(mdab, ndab, 1), &
          wshsgc(lshsgc), work(lwork)
!     check input parameters
ierror = 1
if (nlat < 3) return
ierror = 2
if (nlon < 4) return
ierror = 3
if (mode<0 .or.mode>2) return
ierror = 4
if (nt<1) return
!     set limit for m iin a(m, n), b(m, n) computation
l = min((nlon+2)/2, nlat)
!     set gaussian point nearest equator pointer
late = (nlat+mod(nlat, 2))/2
!     set number of grid points for analysis/synthesis
lat = nlat
if (mode/=0) lat = late
ierror = 5
if (idg<lat) return
ierror = 6
if (jdg<nlon) return
ierror = 7
if (mdab < l) return
ierror = 8
if (ndab < nlat) return
l1 = l
l2 = late
ierror = 9
!     check permanent work space length
if (lshsgc < nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15)return
ierror = 10
!     check temporary work space length
if (mode==0) then
if (lwork <nlat*(nlon*nt+max(3*l2, nlon)))return
else
!     mode.ne.0
if (lwork <l2*(nlon*nt+max(3*nlat, nlon))) return
end if
ierror = 0
!     starting address  fft values
ifft = nlat+2*nlat*late+3*(l*(l-1)/2+(nlat-l)*(l-1))+1
!     set pointers for internal storage of g and legendre polys
ipmn = lat*nlon*nt+1
call shsgc1(nlat, nlon, l, lat, mode, g, idg, jdg, nt, a, b, mdab, ndab, &
wshsgc, wshsgc(ifft), late, work(ipmn), work)
return
end subroutine shsgc
subroutine shsgc1(nlat, nlon, l, lat, mode, gs, idg, jdg, nt, a, b, mdab, &
                  ndab, w, wfft, late, pmn, g)
dimension gs(idg, jdg, nt), a(mdab, ndab, nt), b(mdab, ndab, nt)
dimension w(1), pmn(nlat, late, 3), g(lat, nlon, nt), wfft(1)
!     reconstruct fourier coefficients in g on gaussian grid
!     using coefficients in a, b
!     set m+1 limit for b coefficient calculation
lm1 = l
if (nlon == l+l-2) lm1 = l-1
!     initialize to zero
do 100 k=1, nt
do 100 j=1, nlon
do 100 i=1, lat
g(i, j, k) = 0.0
100 continue
if (mode==0) then
!     set first column in g
m = 0
!     compute pmn for all i and n=m, ..., l-1
call legin(mode, l, nlat, m, w, pmn, km)
do 101 k=1, nt
!     n even
do 102 np1=1, nlat, 2
do 102 i=1, late
g(i, 1, k) = g(i, 1, k)+a(1, np1, k)*pmn(np1, i, km)
102 continue
!     n odd
nl2 = nlat/2
do 103 np1=2, nlat, 2
do 103 i=1, nl2
is = nlat-i+1
g(is, 1, k) = g(is, 1, k)+a(1, np1, k)*pmn(np1, i, km)
103 continue
!     restore m=0 coefficents (reverse implicit even/odd reduction)
do 112 i=1, nl2
is = nlat-i+1
t1 = g(i, 1, k)
t3 = g(is, 1, k)
g(i, 1, k) = t1+t3
g(is, 1, k) = t1-t3
112 continue
101 continue
!     sweep  columns of g for which b is available
do 104 mp1=2, lm1
m = mp1-1
mp2 = m+2
!     compute pmn for all i and n=m, ..., l-1
call legin(mode, l, nlat, m, w, pmn, km)
do 105 k=1, nt
!     for n-m even store (g(i, p, k)+g(nlat-i+1, p, k))/2 in g(i, p, k) p=2*m, 
!     for i=1, ..., late
do 106 np1=mp1, nlat, 2
do 107 i=1, late
g(i, 2*m, k) = g(i, 2*m, k)+a(mp1, np1, k)*pmn(np1, i, km)
g(i, 2*m+1, k) = g(i, 2*m+1, k)+b(mp1, np1, k)*pmn(np1, i, km)
107 continue
106 continue
!     for n-m odd store g(i, p, k)-g(nlat-i+1, p, k) in g(nlat-i+1, p, k)
!     for i=1, ..., nlat/2 (p=2*m, p=2*m+1)
do 108 np1=mp2, nlat, 2
do 109 i=1, nl2
is = nlat-i+1
g(is, 2*m, k) = g(is, 2*m, k)+a(mp1, np1, k)*pmn(np1, i, km)
g(is, 2*m+1, k) = g(is, 2*m+1, k)+b(mp1, np1, k)*pmn(np1, i, km)
109 continue
108 continue
!     now set fourier coefficients using even-odd reduction above
do 110 i=1, nl2
is = nlat-i+1
t1 = g(i, 2*m, k)
t2 = g(i, 2*m+1, k)
t3 = g(is, 2*m, k)
t4 = g(is, 2*m+1, k)
g(i, 2*m, k) = t1+t3
g(i, 2*m+1, k) = t2+t4
g(is, 2*m, k) = t1-t3
g(is, 2*m+1, k) = t2-t4
110 continue
105 continue
104 continue
!     set last column (using a only)
if (nlon== l+l-2) then
m = l-1
call legin(mode, l, nlat, m, w, pmn, km)
do 111 k=1, nt
!     n-m even
do 131 np1=l, nlat, 2
do 131 i=1, late
g(i, nlon, k) = g(i, nlon, k)+2.0*a(l, np1, k)*pmn(np1, i, km)
131 continue
lp1 = l+1
!     n-m odd
do 132 np1=lp1, nlat, 2
do 132 i=1, nl2
is = nlat-i+1
g(is, nlon, k) = g(is, nlon, k)+2.0*a(l, np1, k)*pmn(np1, i, km)
132 continue
do 133 i=1, nl2
is = nlat-i+1
t1 = g(i, nlon, k)
t3 = g(is, nlon, k)
g(i, nlon, k)= t1+t3
g(is, nlon, k)= t1-t3
133 continue
111 continue
end if
else
!     half sphere (mode.ne.0)
!     set first column in g
m = 0
meo = 1
if (mode==1) meo = 2
ms = m+meo
!     compute pmn for all i and n=m, ..., l-1
call legin(mode, l, nlat, m, w, pmn, km)
do 113 k=1, nt
do 113 np1=ms, nlat, 2
do 113 i=1, late
g(i, 1, k) = g(i, 1, k)+a(1, np1, k)*pmn(np1, i, km)
113 continue
!     sweep interior columns of g
do 114 mp1=2, lm1
m = mp1-1
ms = m+meo
!     compute pmn for all i and n=m, ..., l-1
call legin(mode, l, nlat, m, w, pmn, km)
do 115 k=1, nt
do 115 np1=ms, nlat, 2
do 115 i=1, late
g(i, 2*m, k) = g(i, 2*m, k)+a(mp1, np1, k)*pmn(np1, i, km)
g(i, 2*m+1, k) = g(i, 2*m+1, k)+b(mp1, np1, k)*pmn(np1, i, km)
115 continue
114 continue
if (nlon==l+l-2) then
!     set last column
m = l-1
call legin(mode, l, nlat, m, w, pmn, km)
ns = l
if (mode==1) ns = l+1
do 116 k=1, nt
do 116 i=1, late
do 116 np1=ns, nlat, 2
g(i, nlon, k) = g(i, nlon, k)+2.0*a(l, np1, k)*pmn(np1, i, km)
116 continue
end if
end if
!     do inverse fourier transform
do 120 k=1, nt
call hrfftb(lat, nlon, g(1, 1, k), lat, wfft, pmn)
120 continue
!     scale output in gs
do 122 k=1, nt
do 122 j=1, nlon
do 122 i=1, lat
gs(i, j, k) = 0.5*g(i, j, k)
122 continue
return
end subroutine shsgc1
subroutine shsgci(nlat, nlon, wshsgc, lshsgc, dwork, ldwork, ierror)
!     this subroutine must be called before calling shsgc with
!     fixed nlat, nlon. it precomputes quantites such as the gaussian
!     points and weights, m=0, m=1 legendre polynomials, recursion
!     recursion coefficients.
dimension wshsgc(lshsgc)
real dwork(ldwork)
ierror = 1
if (nlat < 3) return
ierror = 2
if (nlon < 4) return
!     set triangular truncation limit for spherical harmonic basis
l = min((nlon+2)/2, nlat)
!     set equator or nearest point (if excluded) pointer
late = (nlat+mod(nlat, 2))/2
l1 = l
l2 = late
ierror = 3
!     check permanent work space length
if (lshsgc < nlat*(2*l2+3*l1-2)+3*l1*(1-l1)/2+nlon+15)return
ierror = 4
if (ldwork < nlat*(nlat+4)) return
ierror = 0
!     set pointers
i1 = 1
i2 = i1+nlat
i3 = i2+nlat*late
i4 = i3+nlat*late
i5 = i4+l*(l-1)/2 +(nlat-l)*(l-1)
i6 = i5+l*(l-1)/2 +(nlat-l)*(l-1)
i7 = i6+l*(l-1)/2 +(nlat-l)*(l-1)
!     set indices in temp work for real gaussian wts and pts
idth = 1
idwts = idth+nlat
iw = idwts+nlat
call shsgci1(nlat, nlon, l, late, wshsgc(i1), wshsgc(i2), wshsgc(i3), &
wshsgc(i4), wshsgc(i5), wshsgc(i6), wshsgc(i7), dwork(idth), &
dwork(idwts), dwork(iw), ierror)
if (ierror/=0) ierror = 5
return
end subroutine shsgci
subroutine shsgci1(nlat, nlon, l, late, wts, p0n, p1n, abel, bbel, cbel, &
                  wfft, dtheta, dwts, work, ier)
dimension wts(nlat), p0n(nlat, late), p1n(nlat, late), abel(1), bbel(1), &
 cbel(1), wfft(1), dtheta(nlat), dwts(nlat)
real pb, dtheta, dwts, work(*)
!     compute the nlat  gaussian points and weights, the
!     m=0, 1 legendre polys for gaussian points and all n, 
!     and the legendre recursion coefficients
!     define index function used in storing
!     arrays for recursion coefficients (functions of (m, n))
!     the index function indx(m, n) is defined so that
!     the pairs (m, n) map to [1, 2, ..., indx(l-1, l-1)] with no
!     "holes" as m varies from 2 to n and n varies from 2 to l-1.
!     (m=0, 1 are set from p0n, p1n for all n)
!     define for 2.le.n.le.l-1
indx(m, n) = (n-1)*(n-2)/2+m-1
!     define index function for l.le.n.le.nlat
imndx(m, n) = l*(l-1)/2+(n-l-1)*(l-1)+m-1
!     preset quantites for fourier transform
call hrffti(nlon, wfft)
!     compute real gaussian points and weights
!     lw = 4*nlat*(nlat+1)+2
lw = nlat*(nlat+2)
call gaqd(nlat, dtheta, dwts, work, lw, ier)
if (ier/=0) return
!     store gaussian weights single precision to save computation
!     in inner loops in analysis
do 100 i=1, nlat
wts(i) = dwts(i)
100 continue
!     initialize p0n, p1n using real dnlfk, dnlft
do 101 np1=1, nlat
do 101 i=1, late
p0n(np1, i) = 0.0
p1n(np1, i) = 0.0
101 continue
!     compute m=n=0 legendre polynomials for all theta(i)
np1 = 1
n = 0
m = 0
call dnlfk(m, n, work)
do 103 i=1, late
call dnlft(m, n, dtheta(i), work, pb)
p0n(1, i) = pb
103 continue
!     compute p0n, p1n for all theta(i) when n.gt.0
do 104 np1=2, nlat
n = np1-1
m = 0
call dnlfk(m, n, work)
do 105 i=1, late
call dnlft(m, n, dtheta(i), work, pb)
p0n(np1, i) = pb
105 continue
!     compute m=1 legendre polynomials for all n and theta(i)
m = 1
call dnlfk(m, n, work)
do 106 i=1, late
call dnlft(m, n, dtheta(i), work, pb)
p1n(np1, i) = pb
106 continue
104 continue
!     compute and store swarztrauber recursion coefficients
!     for 2.le.m.le.n and 2.le.n.le.nlat in abel, bbel, cbel
do 107 n=2, nlat
mlim = min(n, l)
do 107 m=2, mlim
imn = indx(m, n)
if (n >= l) imn = imndx(m, n)
abel(imn)=sqrt(real((2*n+1)*(m+n-2)*(m+n-3))/ &
               real(((2*n-3)*(m+n-1)*(m+n))))
bbel(imn)=sqrt(real((2*n+1)*(n-m-1)*(n-m))/ &
               real(((2*n-3)*(m+n-1)*(m+n))))
cbel(imn)=sqrt(real((n-m+1)*(n-m+2))/ &
               real(((n+m-1)*(n+m))))
107 continue
return
end subroutine shsgci1
