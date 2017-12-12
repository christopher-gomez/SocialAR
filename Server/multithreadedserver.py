import base64
import linecache
import socket
import sys
import threading

from face_recon import Database


def print_exception():
    exc_type, exc_obj, tb = sys.exc_info()
    f = tb.tb_frame
    lineno = tb.tb_lineno
    filename = f.f_code.co_filename
    linecache.checkcache(filename)
    line = linecache.getline(filename, lineno, f.f_globals)
    print 'EXCEPTION IN ({}, LINE {} "{}"): {}'.format(filename, lineno, line.strip(), exc_obj)


class ThreadedServer(object):
    def __init__(self, host, port=5023):
        self.host = host
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind((self.host, self.port))
        self.database = Database()

        print "server set up successfully"

    def listen(self):
        self.sock.listen(5)
        while True:
            client, address = self.sock.accept()
            client.settimeout(60)
            threading.Thread(target=self.__listen_to_client, args=(client, address)).start()

    def __listen_to_client(self, client, address):
        def __display_credentials(username):
            print "The following username was received - ", username

        def __send_data(response):
            size = 16
            while True:
                try:
                    data = client.recv(size)
                    if data:
                        print data
                        break
                    else:
                        raise TypeError('nothing was received')
                except TypeError:
                    print_exception()
                    continue
                except socket.error:
                    client.close()
                    print_exception()
                    return False

            client.send(response)
            print response
            while True:
                try:
                    data = client.recv(size)
                    if data:
                        return True
                    else:
                        raise TypeError('nothing was received')
                except TypeError:
                    print_exception()
                    continue
                except socket.error:
                    client.close()
                    print_exception()

                    return False

        def __recv_data(expectation, response):
            size = 1024
            messege = ""
            print expectation
            client.send(expectation)
            while True:
                try:
                    data = client.recv(size)
                    if data:
                        # print len(data)
                        terminate = data.find('\r\n\r\n')
                        # print terminate
                        if terminate is -1:
                            messege += data
                        else:
                            data = data[:terminate]
                            if data < 24:
                                response = response.format(data)
                            client.send(response)
                            print response
                            messege += data
                            return messege
                    else:
                        print expectation
                        raise error('Client disconnected')
                except socket.error:
                    client.close()
                    print_exception()
                    return None

                except Exception as e:
                    print e.args
                    print e
                    client.close()
                    print_exception()
                    return None

        def __recv_encoded_string_image():

            image = __recv_data("waiting on image",
                                "image is so good")
            import cv2
            import numpy as np
            nparr = np.fromstring(image, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            return img

        def __recv_username_and_encoded_string_image():
            username = __recv_data("wait on username",
                                   "username is a go")
            print username

            image = __recv_encoded_string_image()
            # print len(image)
            return username, image

        def __proceed_client_listen():
            while True:
                choice = __recv_data("waiting on menus",
                                     "option {0} is a go")
                if choice:
                    # print ("choice = " + choice)
                    choice = int(choice)
                    if choice == 1:
                        username, image = __recv_username_and_encoded_string_image()
                        __display_credentials(username=username)

                        self.database.add(name=username, image=image)
                        # do stuff with username and image
                    elif choice == 2:
                        image = __recv_encoded_string_image()
                        name = self.database.comp(image)
                        if name:
                            __send_data(name)
                        else:
                            __send_data("(>.<)")

                    elif choice == 3:
                        exit()

                else:
                    print "incorrect <{0}> given".format(choice)

        __proceed_client_listen()


def main():
    while True:
        port_num = input("Port? ")
        try:
            port_num = int(port_num)
            break
        except ValueError:
            pass

    ThreadedServer('', port_num).listen()


if __name__ == "__main__":
    main()
