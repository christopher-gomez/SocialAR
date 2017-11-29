#!/usr/bin/python
# TCP client example
import base64
import socket,os
import numpy as np
import cv2


client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print ("Enter ip_address or press enter to use ip address of this computer")
ip_address = raw_input()

print ("Connecting to server...")
client_socket.connect((ip_address, 5016))
k = ' '
size = 1024

print ("Connected to server")
while(1):
    k = " "
    print "Do you want to transfer a \n1.Credentials\n2.Image\n"
    k = raw_input()
    if not k:
        continue
    client_socket.send(k)
    k = int (k)

    if(k == 1):
        print "Enter username\n"
        strng = raw_input()
        client_socket.send(strng)
        print "Enter password\n"
        strng = raw_input()
        client_socket.send(strng)

    if (k==2):
        print "Enter file name of the image with extension (example: filename.jpg,filename.png or if a video file then filename.mpg etc) - "
        fname = raw_input()
        fname = './'+fname
        print fname
        fp = open(fname,'rb')
        if not fp:
            print "empty file"
        img = ""
        #convert image to opencv byte string
        while True:
            str = fp.readline(512)
            if not str:
                client_socket.send("")
                break
            print "send"
            client_socket.send(str)
            print str
            print "sended"
            img += str
        print "Data Received successfully"
        #nparr = np.fromstring(img, np.uint8)
        #img_np = cv2.imdecode(nparr, cv2.IMREAD_COLOR) # cv2.IMREAD_COLOR in OpenCV 3.1
        #cv2.imshow("client",img_np)
        #cv2.waitKey()
        fp.close()
    exit()
        #data = 'viewnior '+fname
        #os.system(data)



