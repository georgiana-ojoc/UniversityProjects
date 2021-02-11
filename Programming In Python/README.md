# EncryptedDatabase
Implemented an application in Python using a MySQL database which stores encrypted files  
Works like a shell with the following commands:  
 - upload [path]: encrypts the file from the specified path and stores it in the "encrypted_files" directory  
 - download [name]: decrypts the file with the specified name and stores it in the "decrypted_files" directory  
 - remove [name]: removes the file with the specified name from the "encrypted_files" directory  
 - exit: finishes the execution of the application