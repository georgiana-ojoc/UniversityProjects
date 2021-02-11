import os


def get_extensions(directory):
    extensions = {os.path.splitext(item)[-1].strip('.') for item in os.listdir(directory)
                  if os.path.isfile(os.path.join(directory, item))}
    return sorted(extensions)


if __name__ == '__main__':
    print(get_extensions(r"D:\Program Files\Python\DLLs"))
