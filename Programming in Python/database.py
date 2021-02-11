from getpass import getpass
from mysql.connector import connect


def create_database():
    """
    Reads the connection information from the console.
    Creates the "encrypted_database" database, if it does not already exist.
    """
    with connect(host=input(">>> Enter host: "),
                 user=input(">>> Enter username: "),
                 password=getpass(">>> Enter password: ")) as connection:
        with connection.cursor() as cursor:
            cursor.execute("CREATE DATABASE IF NOT EXISTS encrypted_database")
            print("<<< Created \"encrypted_database\" database (if not existed).")


def create_tables(connection):
    """
    Creates the "files" table, if it does not already exist.
    Creates the "public_keys" table, if it does not already exist.
    Creates the "private_keys" table, if it does not already exist.
    :param connection: an open connection to the "encrypted_database" database
    """
    with connection.cursor() as cursor:
        cursor.execute("CREATE TABLE IF NOT EXISTS files"
                       "(id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, "
                       "name VARCHAR(512) NOT NULL)")
        print("<<< Created \"files\" table (if not existed).")
        cursor.execute("CREATE TABLE IF NOT EXISTS public_keys"
                       "(file_id INT NOT NULL PRIMARY KEY, "
                       "e VARCHAR(2048) NOT NULL, "
                       "n VARCHAR(2048) NOT NULL,"
                       "FOREIGN KEY(file_id) REFERENCES files(id))")
        print("<<< Created \"public_keys\" table (if not existed).")
        cursor.execute("CREATE TABLE IF NOT EXISTS private_keys"
                       "(file_id INT NOT NULL PRIMARY KEY, "
                       "d VARCHAR(2048) NOT NULL, "
                       "p VARCHAR(1024) NOT NULL, "
                       "q VARCHAR(1024) NOT NULL, "
                       "FOREIGN KEY(file_id) REFERENCES files(id))")
        print("<<< Created \"private_keys\" table (if not existed).")
        connection.commit()


def insert_file(connection, name):
    """
    Inserts name into the "files" table.
    :param connection: an open connection to the "encrypted_database" database
    :param name: the file name
    :return: id of inserted name into the "files" table
    """
    with connection.cursor(prepared=True) as cursor:
        cursor.execute("INSERT INTO files(name) VALUES(?)", (name,))
        connection.commit()
        print("<<< Inserted into \"files\".")
        cursor.execute("SELECT id FROM files WHERE name = ?", (name,))
        return cursor.fetchone()[0]


def insert_public_key(connection, identifier, e, n):
    """
    Inserts identifier, e and n into the "public_keys" table.
    :param connection: an open connection to the "encrypted_database" database
    :param identifier: id from the "files" table
    :param e: the public key exponent
    :param n: the semiprime (n = p * q)
    """
    with connection.cursor(prepared=True) as cursor:
        cursor.execute("INSERT INTO public_keys(file_id, e, n) VALUES(?, ?, ?)", (identifier, str(e), str(n)))
        connection.commit()
        print("<<< Inserted into \"public_keys\".")


def insert_private_key(connection, identifier, d, p, q):
    """
    Inserts identifier, d, p and q into the "private_keys" table.
    :param connection: an open connection to the "encrypted_database" database
    :param identifier: id from the "files" table
    :param d: the private key exponent
    :param p: the first prime number
    :param q: the second prime number
    """
    with connection.cursor(prepared=True) as cursor:
        cursor.execute("INSERT INTO private_keys(file_id, d, p, q) VALUES(?, ?, ?, ?)", (identifier, str(d), str(p),
                                                                                         str(q)))
        connection.commit()
        print("<<< Inserted into \"private_keys\".")


def get_identifier(connection, name):
    """
    Gets the identifier of the file with the specified name from the "files" table.
    :param connection: an open connection to the "encrypted_database" database
    :param name: the file name
    :return: id of name if it exists in the "files" table, None otherwise
    """
    with connection.cursor(prepared=True) as cursor:
        cursor.execute("SELECT id FROM files WHERE name = ?", (name,))
        result = cursor.fetchone()
        if result is None:
            return None
        return result[0]


def get_public_key(connection, identifier):
    """
    Gets the public key exponent and the semiprime of the file with the specified identifier from the
    "encrypted_database" database.
    :param connection: an open connection to the "encrypted_database" database
    :param identifier: id from the "files" table
    :return:
        e - the public key exponent
        n - the semiprime (n = p * q)
    """
    with connection.cursor(prepared=True) as cursor:
        cursor.execute("SELECT e, n FROM public_keys WHERE file_id = ?", (identifier,))
        result = cursor.fetchone()
        if result is None:
            return None
        e, n = int(result[0]), int(result[1])
        return e, n


def get_private_key(connection, identifier):
    """
    Gets the private key exponent and the prime numbers of the file with the specified identifier from the
    "encrypted_database" database.
    :param connection: an open connection to the "encrypted_database" database
    :param identifier: id from the "files" table
    :return:
        d - the private key exponent
        p - the first prime number
        q - the second prime number
    """
    with connection.cursor(prepared=True) as cursor:
        cursor.execute("SELECT d, p, q FROM private_keys WHERE file_id = ?", (identifier,))
        result = cursor.fetchone()
        d, p, q = int(result[0]), int(result[1]), int(result[2])
        return d, p, q


def delete_metadata(connection, identifier):
    """
    Deletes the row with the specified identifier from the "public_keys" table.
    Deletes the row with the specified identifier from the "private_keys" table.
    Deletes the row with the specified identifier from the "files" table.
    Sets the next identifier from the "files" table as the maximum identifier + 1, in case the deleted file was the last
    one inserted.
    :param connection: an open connection to the "encrypted_database" database
    :param identifier: id from the "files" table
    """
    with connection.cursor(prepared=True) as cursor:
        cursor.execute("DELETE FROM public_keys WHERE file_id = ?", (identifier,))
        print("<<< Deleted from \"public_keys\".")
        cursor.execute("DELETE FROM private_keys WHERE file_id = ?", (identifier,))
        print("<<< Deleted from \"private_keys\".")
        cursor.execute("DELETE FROM files WHERE id = ?", (identifier,))
        print("<<< Deleted from \"files\".")
        connection.commit()
        set_identifier(connection)


def set_identifier(connection):
    """
    Sets the AUTO_INCREMENT from the "files" table as the MAX(id) + 1.
    :param connection: an open connection to the "encrypted_database" database
    """
    with connection.cursor() as cursor:
        cursor.execute("SELECT MAX(id) FROM files")
        maximum_identifier = cursor.fetchone()[0]
        cursor.execute("ALTER TABLE files AUTO_INCREMENT = %s" % str(maximum_identifier + 1))
        print("<<< Reset identifier.")
        connection.commit()
