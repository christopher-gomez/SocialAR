import cv2
import sys

CascPath   = sys.argv [ 1 ]
FaceCascade = cv2.CascadeClassifier ( CascPath )

VideoCapture = cv2.VideoCapture ( 0 )

while True:
    #capture frame by frame
    Ret, Frame = VideoCapture.read();

    Grey = cv2.cvtColor ( Frame, cv2.COLOR_BGR2GRAY )
    Face = FaceCascade.detectMultiScale (
            Grey,
            scaleFactor = 1.1,
            minNeighbors = 5,
            minSize = ( 30, 30 ),
            flags       = 0 #cv2.CV_HAAR_SCALE_IMAGE
            )


    for ( x, y, w, h ) in Face:
        cv2.rectangle ( Frame, ( x, y ), ( x+w, y+h ), ( 0, 255, 0 ), 2 )
            

    cv2.imshow ("Video" , Frame )
    if cv2.waitKey ( 1 ) & 0xFF == ord ( 'q' ):
        break

VideoCapture.release()
cv2.destroyAllWindows()

