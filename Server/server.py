from PIL import Image
import socket
import base64



#could be another function instead of this
def DisplayImage (img):
    import numpy as np
    import cv2

    nparr = np.fromstring(img, np.uint8)
    img_np = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED) # cv2.IMREAD_COLOR in OpenCV 3.1
    print type(img_np)
    try :
        cv2.imshow("server",img_np)
        cv2.waitKey(0)
        cv2.destroyAllWindows()
    except:
        print("Error: Improper image was received")
    print("Press any key to continue...")

def DisplayCredentials (username):
    print "The following username was received - ",username



server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
ip_address = raw_input("Enter ip_address or press enter to use ip address of this computer\n")
print ("Setting up server...")
server_socket.bind((ip_address, 5022))
server_socket.listen(5)
print ("Server set up!")


client_socket, address = server_socket.accept()
print "Connected to - ",address,"\n"
while (1):
    print "Waiting for data"
    choice_str = client_socket.recv(1024)
    print repr (choice_str)
    if not choice_str:
        continue
    choice_str = choice_str.split('\n')[0]
    choice =int(choice_str)
    if(choice == 1):
        client_socket.send("waiting for username\n");
        username = client_socket.recv(1024)
        DisplayCredentials(username=username)
        print "Credentials received successfully"
        client_socket.send("Credentials received successfully\n");

    elif (choice == 2):
        client_socket.send("waiting for image size\n");
        print "Receiving data"
        temp_size = client_socket.recv(1024)
        print repr(temp_size)
        if not temp_size:
            continue
        temp_size = temp_size.split('\n')[0]
        client_size =int(temp_size)
        print client_size
        img = ""
        client_socket.send("waiting for image\n");

        server_size = 0
        while server_size < client_size:
            str = client_socket.recv(1024)
            # print ()
            # print ()
            # print str
            # print ()
            # print ()
            img+= str
            server_size += len(str)
            print server_size

        print "Image received successfully"
        client_socket.send("Image received successfully\n");
        print len(img)
        img = base64.b64decode(img)
        DisplayImage(img=img)
    elif choice == 3:
        exit()




        #exit()



