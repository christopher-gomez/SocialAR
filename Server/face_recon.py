import face_recognition
import os
import numpy as np

class database :
    #constructor, already tested
    def __init__(self):
        print ("database started")
        self.list = {}
        for filename in os.listdir(path):
            print filename
            temp_image = face_recognition.load_image_file(path+filename)
            temp_encoding = face_recognition.face_encodings(temp_image)[0]
            name = os.path.splitext(filename)[0]
            self.list.update( { name:temp_encoding } )

    #needs to be tested
    def add(self, name, image):
        if type(image) is np:
            pass
        elif type(image) is string:
            image = np.fromstring(image, dtype=np.uint8)
        else:
            return False;
        if self.list[name]:
            temp_encoding = face_recognition.face_encodings(image)[0]
            self.list.update( { name:temp_encoding } )
            cv2.imwrite( path + name + ".jpg", image );

    #needs to be tested
    def compare (self, image):
        if type(image) is np:
            pass
        elif type(image) is string:
            image = np.fromstring(image, dtype=np.uint8)
        else:
            return False

        temp_encoding = face_recognition.face_encodings(image)[0]
        results = face_recognition.compare_faces(self.list.items(),temp_encoding) 
        #needs to evaluate results ....
        #for result in results:
        #   if result:
        #       true











#main already tested
if __name__ == "__main__":
    print "hello"
    path = "./Database/"
    x = database ()


