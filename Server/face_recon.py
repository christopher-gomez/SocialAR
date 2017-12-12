import face_recognition
import os
import numpy as np
import cv2
from collections import OrderedDict
from operator import itemgetter

LENGTH_COEFF = 0.5

class Database:
    '''Manages database of images, who's file name represents the image of the user.
    '''
    def __init__(self):
        '''
        loads up the database
        starts up the server
        '''
        self.list = OrderedDict()
        self.path = "./Database/"
        for filename in os.listdir(self.path):
            temp_image = face_recognition.load_image_file(self.path + filename)
            temp_encoding = face_recognition.face_encodings(temp_image)[0]
            username = os.path.splitext(filename)[0]
            self.list.update({username: temp_encoding})

    # needs to be convert to allow multiple pictures of same name to allow more
    # accurate results
    def add(self, name, image):
        '''
        adds a file with [name of user].jpg which contains the image of the user

        :param name: name of user
        :param image: image of user
        :return: true if image is added, otherwise false
        '''
        assert isinstance(image, np.ndarray)

        if name in self.list.keys():
            print "name already exists"
            return False
        else:
            temp_encoding = face_recognition.face_encodings(image)[0]
            self.list.update({name: temp_encoding})
            img = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
            cv2.imwrite(self.path + name + ".jpg", img)
            return True

    # needs to be convert to allow multiple pictures of same name to allow more
    # accurate results
    def comp(self, image):
        ''''''
        assert isinstance(image, np.ndarray)

        temp_encoding = face_recognition.face_encodings(image)[0]
        results = face_recognition.face_distance(self.list.values(), temp_encoding)

        # possible to through each face
        index, length = min(enumerate(results), key=itemgetter(1))
        print length

        # truths = [i for i, x in enumerate(results) if x]
        if length < LENGTH_COEFF:
            answer = self.list.items()[index][0]
            return answer
        else:
            return None


def main():
    print "opening image"
    img = cv2.imread('unknown.jpg')
    image = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

    print "loading database"
    x = Database()

    print "comparing unknown.jpg"
    name = x.comp(image=image)
    print "results"
    if name:
        print "person in database {}".format(name)
        if x.add(name=name, image=image):
            print "added successfully"
        else:
            print "failed to add"
    else:
        print "person not in database"
    print "done"


# main already tested
if __name__ == "__main__":
    main()
