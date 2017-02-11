from types cimport *


# cython template[basis_type,matrix_type,N_type], do not call from script
cdef spin_op_inplace_c(npy_intp Ns,matrix_type * psi_in, matrix_type * psi_out,
                    str opstr, NP_INT32_t * indx, scalar_type J):

    cdef npy_intp i
    cdef int j,error
    cdef int N_indx = len(opstr)
    cdef bool a
    cdef scalar_type M_E
    cdef unsigned char[:] c_opstr = bytearray(opstr,"utf-8")
    cdef npy_intp one = 1

    cdef char I = "I"
    cdef char x = "x"
    cdef char y = "y"
    cdef char z = "z"
    cdef char p = "+"
    cdef char m = "-"

    error = 0

    for i in range(Ns): #loop over basis
        M_E = psi_in[i]

        if M_E != 0.0:
            r = i
            for j in range(N_indx-1,-1,-1): #loop over the copstr
                b = ( one << indx[j] ) #put the bit 1 at the place of the bit corresponding to the site indx[j]; ^b = flipbil
                a = ( r >> indx[j] ) & 1 #checks whether spin at site indx[j] is 1 ot 0; a = return of testbit
                if c_opstr[j] == I:
                    continue
                elif c_opstr[j] == z:
                    M_E *= (1.0 if a else -1.0)
                elif c_opstr[j] == x:
                    r = r ^ b
                elif c_opstr[j] == y:
                    r = r ^ b
                    M_E *= (1.0j if a else -1.0j)
                elif c_opstr[j] == p:
                    M_E *= (0.0 if a else 2.0)
                    r = r ^ b
                elif c_opstr[j] == m:
                    M_E *= (2.0 if a else 0.0)
                    r = r ^ b
                else:
                    error = 1
                    return error

                if M_E == 0.0:
                    break
            M_E *= J
            if matrix_type is float or matrix_type is double or matrix_type is longdouble:
                if M_E.imag != 0.0:
                    error = -1
                    return error

                psi_out[r] += M_E.real
            else:
                psi_out[r] += M_E

    return error



def spin_op_inplace(object[matrix_type,ndim=1] psi_in, object[matrix_type,ndim=1] psi_out,
                    str opstr, object[NP_INT32_t,ndim=1] indx, scalar_type J):
    cdef npy_intp Ns = psi_in.shape[0]
    return spin_op_inplace_c(Ns,&psi_in[0],&psi_out[0],opstr,&indx[0],J)