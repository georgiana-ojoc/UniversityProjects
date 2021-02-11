import sympy
import time


def get_prime_numbers(digits):
    """
    Produces two random prime numbers.
    :param digits: the number of digits of each prime number
    :return: two random prime numbers (p < q)
    """
    seed = int(time.time() * 10 ** (digits - len(str(int(time.time())))))
    p = sympy.nextprime(seed)
    q = sympy.nextprime(p)
    return p, q


def get_carmichael(p, q):
    """
    Computes the Carmichael number of the Euler's Totient.
    :param p: the first prime number
    :param q: the second prime number
    :return: the least common multiple of p - 1 and q - 1
    """
    return (p - 1) * (q - 1) // apply_euclid(p - 1, q - 1)


def get_public_exponent(maximum):
    """
    Computes the public key exponent.
    :param maximum: the end of the range
    :return: a random prime number in the range [2, maximum)
    """
    return sympy.randprime(2, maximum)


def get_private_exponent(e, m):
    """
    Computes the private key exponent.
    :param e: the public key exponent
    :param m: the modulus
    :return: the modular multiplicative inverse of e modulo m
    """
    b = get_modular_inverse(e, m)
    if e == b:
        b += m
    return b


def encrypt_number(m, e, n):
    """
    Computes the encryption of a number using the RSA algorithm.
    :param m: the number to be encrypted
    :param e: the public key exponent
    :param n: the semiprime
    :return: m powered by e modulo n
    """
    return pow(m, e, n)


def decrypt_number(m, d, p, q):
    """
    Computes the decryption of a number using the RSA algorithm with the Chinese Remainder Theorem.
    :param m: the number to be decrypted
    :param d: the private key exponent
    :param p: the first prime number
    :param q: the second prime number
    :return: the decrypted number
    """
    first_exponent = d % (p - 1)
    second_exponent = d % (q - 1)
    modular_inverse = get_modular_inverse(p, q)
    x = pow(m % p, first_exponent, p)
    y = pow(m % q, second_exponent, q)
    return x + p * (((y - x) * modular_inverse) % q)


def apply_euclid(a, b):
    """
    Applies the Euclidean algorithm on two numbers.
    :param a: the first number
    :param b: the second number
    :return: the greatest common divisor of a and b
    """
    while a != 0:
        a, b = b % a, a
    return b


def apply_extended_euclid(a, b):
    """
    Applies the extended Euclidean algorithm on two numbers.
    :param a: the first number
    :param b: the second number
    :return:
        gcd - the greatest common divisor of a and b
        x, y - the Bézout coefficients for a and b (ax + by = gcd)
    """
    if a == 0:
        return b, 0, 1
    gcd, x, y = apply_extended_euclid(b % a, a)
    x, y = y - (b // a) * x, x
    return gcd, x, y


def get_modular_inverse(a, m):
    """
    Computes the modular multiplicative inverse of two numbers.
    :param a: the first number
    :param m: the second number
    :return: the modular multiplicative inverse of a modulo m
    """
    gcd, x, y = apply_extended_euclid(a, m)
    if gcd != 1:
        raise Exception("The modular multiplicative inverse of {} modulo {} does not exist.".format(a, m))
    else:
        return x % m
