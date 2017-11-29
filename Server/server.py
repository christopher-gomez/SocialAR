from PIL import Image
import socket



#could be another function instead of this
def DisplayImage (img):
    import numpy as np
    import cv2

    nparr = np.fromstring(img, np.uint8)
    img_np = cv2.imdecode(nparr, cv2.IMREAD_UNCHANGED) # cv2.IMREAD_COLOR in OpenCV 3.1
    print type(img_np)
    try :
        cv2.imshow("server",img_np)
    except:
        print("Error: Improper image was received")
    print("Press any key to continue...")
    cv2.waitKey()

def DisplayCredentials (username, password):
    print "The following username was received - ",username
    print "The following password was received - ",password
    print("Press any key to continue...")
    cv2.waitKey()



server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
ip_address = raw_input("Enter ip_address or press enter to use ip address of this computer\n")
print ("Setting up server...")
server_socket.bind((ip_address, 5016))
server_socket.listen(5)
print ("Server set up!")


client_socket, address = server_socket.accept()
print "Connected to - ",address,"\n"
while (1):
    choice = client_socket.recv(1024)
    if not choice:
        continue
    choice = int(choice)
    if(choice == 1):
        print("Enter your Facebook username")
        username = client_socket.recv(1024)
        print("Enter your Facebook password")
        password = client_socket.recv(1024)
        DisplayCredentials(username=username,password=password)
        print "Data received successfully"

    elif (choice == 2):
        print "Receiving data"
        img = ""

        while True:
            print "recv"
            str = client_socket.recv(512)
            print "recved"
            if not str:
                break
            print str
            img+= str

        print "Data received successfully"
        DisplayImage(img=img)
    exit()




        #exit()



