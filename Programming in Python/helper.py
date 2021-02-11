import os

DECRYPTED_DIRECTORY = os.path.join(os.getcwd(), "decrypted_files")
ENCRYPTED_DIRECTORY = os.path.join(os.getcwd(), "encrypted_files")


def print_commands():
    """
    Prints the commands format and description.
    """
    print("Commands:")
    print(" - upload <path>: encrypts file from specified path and stores it in \"encrypted_files\" directory")
    print(" - download <name>: decrypts file with specified name and stores it in \"decrypted_files\" directory")
    print(" - remove <name>: removes file with specified name from \"encrypted_files\" directory")
    print(" - exit: finishes execution")


def create_directories():
    """
    Creates the "encrypted_files" directory in the current directory, if it does not already exist.
    Creates the "decrypted_files" directory in the current directory, if it does not already exist.
    """
    if not exists(ENCRYPTED_DIRECTORY):
        os.mkdir(ENCRYPTED_DIRECTORY)
    print("<<< Created \"encrypted_files\" directory (if not existed).")
    if not exists(DECRYPTED_DIRECTORY):
        os.mkdir(DECRYPTED_DIRECTORY)
    print("<<< Created \"decrypted_files\" directory (if not existed).")


def get_number_of_bytes(number):
    """
    Computes the number of bytes of the specified number.
    :param number: the number
    :return: the number of bytes
    """
    bits = number.bit_length()
    result = bits // 8
    if bits % 8:
        result += 1
    return result


def exists(path):
    """
    Checks if the specified path exists into the local file system.
    :param path: the path
    :return: True if it exists, False otherwise
    """
    return os.path.exists(path)


def is_file(path):
    """
    Checks if the specified path is a file.
    :param path: the path
    :return: True if it is a file, False otherwise
    """
    return os.path.isfile(path)


def get_name(path):
    """
    Computes the base name of the specified path.
    :param path: the path
    :return: the base name
    """
    return os.path.basename(path)


def get_content(path):
    """
    Reads the content from the specified path.
    :param path: the path
    :return: the content
    """
    with open(path, "rb") as file:
        return file.read()
