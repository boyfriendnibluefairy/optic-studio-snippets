! Note: I purchased the book from SPIE and it says there that this macro is supposed to be
! included in some versions of OpticStudio. In our version, it's not included so I have to
! retype it. To save you from retyping this macro, I am sharing this file. To Donald
! O'Shea and Julie Bently, your book is reader-friendly and visually explains some of the
! fundamentals before displaying unfamiliar plots to beginners. Keep up the good work!
! Live long and prosper!



! this macro calculates the transverse ray aberrations
! v0.1 MRH: 202-0813
! 2020-09-17: updated the noncolor terms to have the correct sign
! JLB 2021-01-18 Reordered the coefficients and names to match ZOS
! JLB 2022-07-23 updated formating to fit SPIE text page

REWIND ! REWIND is used to overwrite previous ZPL window output
PRINT "THIRD"
! SYPR() is used to read System Parameter, code 16 means Lens Title
dummy = SYPR(16)
! $BUFFER() retrieves the current string data stored in Zemax's internal buffer
str$ = $BUFFER()
IF SLEN(str$) > 0 THEN PRINT "Title: ", $BUFFER()
! PRINT
PRINT "Primary Wavelength:    ", WAVL(PWAV()), " um"
! PRINT

w = WAVL(PWAV()) / 1000
DECLARE t, DOUBLE, 1, 11

s$ = "     ",
PRINT "Surf ", "   ", "TSPH", s$, "TTCO", s$, "TAST" s$, "TPFC", s$, "TSFC", s$, "TTFC", s$, "TDIS", s$, "TAXC", s$, "TLAC"

! OPEV() function allows you to access the value of optimization operand 
!     without explicitly adding it to the merit function.
! OCOD() function retrieves the numerical code associated
!     with a specific optimization operand.
! PWAV() = "print system wavelength"
! get paraxial values for image space
m=OPEV(OCOD("PARB"), NSUR(), PWAV(), 0, 0, 0, 1)
n=OPEV(OCOD("PARC"), NSUR(), PWAV(), 0, 0, 0, 1)
nu = INDX(NSUR()) * m / n

! get the stop surface
GETSYSTEMDATA 1
ss = VEC1 (23)

! get the min/max index values for axial and lateral color
mm=1
xx=1
FOR i=1, SYPR(201), 1
    IF WAVL(i) < WAVL(mm) THEN mm=i
    IF WAVL(i) > WAVL(xx) THEN xx=i
NEXT

DECLARE nm, DOUBLE, 1, NSUR()+1
DECLARE nx, DOUBLE, 1, NSUR()+1
twav=PWAV()
PWAV mm
FOR i=0, NSUR(), 1
    nm(i + 1) = INDX(i)
NEXT
PWAV xx
FOR i = 0, NSUR(), 1
    nx(i + 1) = INDX(i)
NEXT
PWAV twav

nus = 0
FOR surf=1, NSUR(), 1
    ! get wavefront coefficients
    w040 = OPEV(OCOD("SPHA"), surf, PWAV(), 0, 0, 0, 0)
    w131 = OPEV(OCOD("COMA"), surf, PWAV(), 0, 0, 0, 0)
    w222 = OPEV(OCOD("ASTI"), surf, PWAV(), 0, 0, 0, 0)
    w220 = OPEV(OCOD("FCUR"), surf, PWAV(), 0, 0, 0, 0)
    w311 = OPEV(OCOD("DIST"), surf, PWAV(), 0, 0, 0, 0)
    
    ! calculate Seidel coefficients
    s1 = (8 * w) * w040
    s2 = (2 * w) * w131
    s3 = (2 * w) * w222
    ! There is a bug between the reported Seidel and TRA...
    ! but TRA is the correct one.
    s4 = (4 * w) * w220 # as reported in 'Seidel Aberration Coefficients' section
    ! s4 = (4 * w) * w220 - (2 * w) * w222
    s5 = (2 * w) * w311
    
    ! calculate transverse ray aberrations
    tsph = s1 / (2 * nu)
    tsco = s2 / (2 * nu)
    ttco = 3 * s2 / (2 * nu)
    tast = s3 / (nu)
    tpfc = s4 / (2 * nu)
    tsfc = (s3 + s4) / (2 * nu)
    tstf = (3 * s3 + s4) / (2 * nu)
    tdis = s5 / (2 * nu)
    
    ! cl = -ni_m * ys_m * dn
    !     ni_m = nu_m + INDX * y_m * CURV
    !     nu_m = u_m * INDX = m_m / n_m * INDX
    !     dn = (nm2 - nx2) / n2 - (nm1 - nx1) / n1
    ! ct = -ni_c * y_c * dn
    m_m = OPEV(OCOD("PARB"), surf, PWAV(), 0, 0, 0, 1)
    n_m = OPEV(OCOD("PARC"), surf, PWAV(), 0, 0, 0, 1)
    y_m = OPEV(OCOD("PARY"), surf, PWAV(), 0, 0, 0, 1)
    m_c = OPEV(OCOD("PARB"), surf, PWAV(), 0, 1, 0, 0)
    n_c = OPEV(OCOD("PARC"), surf, PWAV(), 0, 1, 0, 0)
    y_c = OPEV(OCOD("PARY"), surf, PWAV(), 0, 1, 0, 0)

    nu_m = 0
    IF ABSO(n_m) > 0 THEN nu_m = m_m / n_m * INDX(surf)
    ni_m = nu_m + INDX(surf) * y_m * CURV(surf)
    
    nu_c = 0
    IF ABSO(n_c) > 0 THEN nu_c = m_c / n_c * INDX(surf)
    ni_c = nu_c + INDX(surf) * y_c * CURV(surf)
    
    dn = ((nm(surf + 1) - nx(surf + 1)) / INDX(surf)) - ((nm(surf) - nx(surf)) / INDX(surf - 1))
    
    cl = -ni_m * y_m * dn
    ct = -ni_c * y_m * dn
    
    taxc = cl / nu
    tlac = ct / nu
    
    ! keep a running sum of all transverse ray aberrations
    t(1) = t(1) + tsph
    ! t(2) = t(2) + tsco
    t(3) = t(3) + ttco
    t(4) = t(4) + tast
    t(5) = t(5) + tpfc
    t(6) = t(6) + tsfc
    t(7) = t(7) + tstf
    t(8) = t(8) + tdis
    t(9) = t(9) + taxc
    t(10) = t(10) + tlac

s$ = "   "

    FORMAT 3.0
    s$ = $STR(surf) + " ",
    s$ = $LEFTSTRING(s$, 4),
    
    IF surf == ss THEN s$ = "STO "
    IF surf == NSUR() THEN s$ = "IMA "
    PRINT s$, "",
    
    FORMAT 9.4
    PRINT tsph,
    !PRINT tsco,
    PRINT ttco,
    PRINT tast,
    PRINT tpfc,
    PRINT tsfc,
    PRINT tstf,
    PRINT tdis,
    PRINT taxc,
    PRINT tlac
NEXT

PRINT "TOT ", t(1), t(3), t(4), t(5), t(6), t(7), t(8), t(9), t(10)