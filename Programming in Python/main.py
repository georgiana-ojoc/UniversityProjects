from database import *
from helper import *
from mysql.connector import Error
from rsa import *

DATABASE = "encrypted_database"

UPLOAD = "upload"
DOWNLOAD = "download"
REMOVE = "remove"

BITS = 512
GAP_BYTES = 4
PAD_BYTES = 1

ENDIAN = "little"


def upload(connection, path):
    """
    Generates the keys and stores them into the database.
    Gets the public key from the database.
    Encrypts the content of the file from the specified path block by block, using the RSA algorithm.
    Pads each block with a random byte, so that to provide ciphertext indistinguishability under a chosen-plaintext
    attack.
    Writes the number of bytes of each encrypted block before it, so that to decrypt each block accordingly.
    :param connection: an open connection to the database
    :param path: the path of the file to be uploaded
    """
    if not exists(path):
        print("<<< The path \"%s\" does not exist." % path)
        return

    if not is_file(path):
        print("<<< The path \"%s\" is not a file." % path)
        return

    name = get_name(path)
    encrypted_file = os.path.join(ENCRYPTED_DIRECTORY, name)
    if exists(encrypted_file):
        print("<<< The file \"%s\" was already encrypted." % path)
        return

    identifier = produce_metadata(connection, name)

    content = get_content(path)
    e, n = get_public_key(connection, identifier)

    block_size = get_number_of_bytes(n) - GAP_BYTES
    with open(encrypted_file, "wb") as file:
        for index in range(0, len(content), block_size):
            block = content[index:index + block_size] + os.urandom(PAD_BYTES)
            encrypted_number = encrypt_number(int.from_bytes(block, byteorder=ENDIAN), e, n)
            encrypted_number_size = get_number_of_bytes(encrypted_number)
            file.write(encrypted_number_size.to_bytes(length=get_number_of_bytes(encrypted_number_size),
                                                      byteorder=ENDIAN))
            file.write(encrypted_number.to_bytes(length=encrypted_number_size, byteorder=ENDIAN))
    print("<<< Encrypted \"%s\" into \"%s\"." % (name, ENCRYPTED_DIRECTORY))


def download(connection, name):
    """
    Gets the private key from the database.
    Decrypts the content of the file with the specified name block by block, using the RSA algorithm with the Chinese
    Remainder Theorem.
    :param connection: an open connection to the database
    :param name: the name of the file to be downloaded
    """
    encrypted_file = os.path.join(ENCRYPTED_DIRECTORY, name)
    if not exists(encrypted_file):
        print("<<< The file \"%s\" was not encrypted." % name)
        return

    decrypted_file = os.path.join(DECRYPTED_DIRECTORY, name)
    if exists(decrypted_file):
        print("<<< The file \"%s\" was already decrypted." % name)
        return

    with open(encrypted_file, "rb") as file:
        encrypted_content = file.read()
    d, p, q = get_private_key(connection, get_identifier(connection, name))

    with open(decrypted_file, "wb") as file:
        index = 0
        while index < len(encrypted_content):
            encrypted_block_size = encrypted_content[index]
            encrypted_block = encrypted_content[index + 1:index + encrypted_block_size + 1]
            encrypted_number = int.from_bytes(encrypted_block, byteorder=ENDIAN)
            decrypted_number = decrypt_number(encrypted_number, d, p, q)
            file.write(decrypted_number.to_bytes(length=get_number_of_bytes(decrypted_number), byteorder=ENDIAN)[:-1])
            index += encrypted_block_size + 1
    print("<<< Decrypted \"%s\" into \"%s\"." % (name, DECRYPTED_DIRECTORY))


def remove(connection, name):
    """
    Deletes the file name and the keys from the database.
    Removes the encrypted file from the local file system.
    :param connection: an open connection to the database
    :param name: the name of the file to be downloaded
    """
    encrypted_file = os.path.join(ENCRYPTED_DIRECTORY, name)
    if not exists(encrypted_file):
        print("<<< The file \"%s\" was not encrypted." % name)
        return

    delete_metadata(connection, get_identifier(connection, name))
    os.remove(encrypted_file)
    print("<<< Removed \"%s\" from \"%s\"." % (name, ENCRYPTED_DIRECTORY))


def produce_metadata(connection, name):
    """
    Stores the file name into the database.
    Generates the public key exponent and the semiprime and stores them into the database.
    Generates the private key exponent and the prime numbers and stores them into the database.
    :param connection: an open connection to the database
    :param name: the name of the file to be stored
    :return: the identifier of the stored file
    """
    file_id = insert_file(connection, name)

    p, q = get_prime_numbers(len(str(2 ** BITS - 1)))
    n = p * q
    carmichael = get_carmichael(p, q)
    e = get_public_exponent(carmichael)
    d = get_private_exponent(e, carmichael)

    insert_public_key(connection, file_id, e, n)
    insert_private_key(connection, file_id, d, p, q)

    return file_id


def main():
    """
    Prints the commands.
    Creates the directories.
    Creates the database.
    Creates the tables.
    Reads commands from the console and processes them.
    """
    print_commands()
    try:
        create_directories()
        create_database()
        with connect(host=input(">>> Enter host: "),
                     user=input(">>> Enter username: "),
                     password=getpass(">>> Enter password: "),
                     database=DATABASE) as connection:
            create_tables(connection)
            while True:
                command = input(">>> ").split(maxsplit=1)
                if len(command) == 0 or command[0] == "exit":
                    print("<<< Have a good day!")
                    break
                if command[0] not in (UPLOAD, DOWNLOAD, REMOVE) or len(command) != 2:
                    print("<<< Invalid command.")
                elif command[0] == UPLOAD:
                    upload(connection, command[1])
                elif command[0] == DOWNLOAD:
                    download(connection, command[1])
                elif command[0] == REMOVE:
                    remove(connection, command[1])
    except Error as error:
        print(error)


if __name__ == '__main__':
    main()
