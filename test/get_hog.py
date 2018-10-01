import matplotlib.pyplot as plt

from skimage.feature import hog
from skimage import data, exposure

import numpy as np
import cv2
import os

print ("Import Successful")

def get_hog(image):

    image = cv2.resize(image, (64, 128))
    fd, hog_image = hog(image, orientations=8, pixels_per_cell=(16, 16), cells_per_block=(1, 1), visualize=True, multichannel=True)
    
    return fd

def get_features(dirname):

    images = os.listdir(dirname)
    features_hog = []

    f = open("image_names_list_genre2.txt", 'w')

    for i, name in enumerate(images):
        print i
        image = cv2.imread(dirname+'/'+name)
        f.write(dirname+'/'+name+'\n')
        fd = get_hog(image)
        features_hog.append(fd)
    f.close()
    features_hog = np.asarray(features_hog)
    np.savetxt('Features_hog_genre2.txt', features_hog)

    return


def my_svm(X_train, y_train, X_val, y_val, X_test, test_im_names):

    print "X_train shape, X_val shape", X_train.shape, X_val.shape

    X_train = list(X_train)
    y_train = list(y_train)

    X_val = list(X_val)
    y_val = list(y_val)

    X_test = list(X_test)

    lin_clf = svm.LinearSVC(multi_class='ovr')
    print "SVM Training"
    lin_clf.fit(X_train, y_train) 
    print "SVM Trained"
    '''
    print "SVM predict"
    y_pred = lin_clf.predict(X_val)

    hit = 0.0
    total = len(y_val)

    for i in range(total):
        if y_val[i] == y_pred[i]:
            hit+=1.0
    print "Accuracy", (float(hit)/total)*100
    '''
    print "Working on test data"
    #Test data work
    y_test = lin_clf.predict(X_test)

    print "Test labels", y_test[:100]
        
    ds = {1:'dry_cans', 0:'dry_other', 4:'dry_paper', 2:'dry_plastic', 3:'wet'}
    f = open('test_ouput.csv', 'w')

    for i in range(len(y_test)):
        label = y_test[i]
        s = test_im_names[i]+","+ds[label]+"\n"
        f.write(s)
    f.close()

    return 

if __name__ == "__main__":

    dirname = "./genre2"
    get_features(dirname)

    #Have to update for genre3 and genre4
    #Manually change file names for images and hog features in the get_features() function.

    exit(0)
