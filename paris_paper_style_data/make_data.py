import os
import pdb
import numpy as np
import cv2
import scipy.io

classes = ['action','adventure', 'animation', 'biography', 'comedy', 'crime' , 'documentary' , 'drama' , 'family', 'fantasy', 'history', 'horror', 'music', 'musical', 'mystery', 'romance', 'sci-fi', 'short', 'sport', 'thriller', 'war','western']

'''
for name in classes:
    os.system('mkdir ./data/'+name)
'''
d = {}
for genre in classes:
    d[genre] = 0

f = open('dataset_us.txt')

'''
Selected genres:
    genre1 : horror, mystery, thriller
    genre2 : adventure, animation, comedy
    genre3 : action, crime, drama
    genre4 : biography, drama, history
'''

genre1 = ['horror', 'mystery', 'thriller']
genre2 = ['adventure', 'animation', 'comedy']
genre3 = ['action', 'crime', 'drama']
genre4 = ['biography', 'drama', 'history']

l1 = []
l2 = []
l3 = []
l4 = []



for idx, line in enumerate(f):
    line = line.strip().split('|')
    image = line[1].strip()
    genres = line[2].strip().split(',')

    if len(genres) < 3:
        continue
    
    print idx, image, genres
    
    #genre1
    flag = 0
    for genre in genres:
        genre = genre.strip().lower()
        if genre not in d:
            continue
        if genre not in genre1:
            flag = 1
            break
    if flag == 0:
        os.system('cp ./images/'+image+' ./data/genre1/')
        im = cv2.imread('./images/'+image)
        l1.append((image, im.shape))
        continue
        

    #genre2
    flag = 0
    for genre in genres:
        genre = genre.strip().lower()
        if genre not in d:
            continue
        if genre not in genre2:
            flag = 1
            break
    if flag == 0:
        os.system('cp ./images/'+image+' ./data/genre2/')
        im = cv2.imread('./images/'+image)
        l2.append((image, im.shape))
        continue

    #genre3
    flag = 0
    for genre in genres:
        genre = genre.strip().lower()
        if genre not in d:
            continue
        if genre not in genre3:
            flag = 1
            break
    if flag == 0:
        os.system('cp ./images/'+image+' ./data/genre3/')
        im = cv2.imread('./images/'+image)
        l3.append((image, im.shape))
        continue

    #genre4
    flag = 0
    for genre in genres:
        genre = genre.strip().lower()
        if genre not in d:
            continue
        if genre not in genre4:
            flag = 1
            break
    if flag == 0:
        os.system('cp ./images/'+image+' ./data/genre4/')
        im = cv2.imread('./images/'+image)
        l4.append((image, im.shape))
        continue



    '''
    for genre in genres:
        genre = genre.strip().lower()
        if genre not in d:
            continue
        s = "./data/"+genre+"/"+str(d[genre])+"_"+genre+".jpg"
        print s
        d[genre] += 1
        os.system('cp ./images/'+image+' '+s)
    '''

print len(l1), len(l2), len(l3), len(l4)

city = []
name = []
fullname = []
imsize = []

for i in l1:
    city.append('genre1')
    name.append(i[0])
    imsize.append(i[1])
    fullname.append('genre1/'+i[0])

for i in l2:
    city.append('genre2')
    name.append(i[0])
    imsize.append(i[1])
    fullname.append('genre2/'+i[0])

for i in l3:
    city.append('genre3')
    name.append(i[0])
    imsize.append(i[1])
    fullname.append('genre3/'+i[0])


for i in l4:
    city.append('genre4')
    name.append(i[0])
    imsize.append(i[1])
    fullname.append('genre4/'+i[0])

adict = {}
adict['name'] = name
adict['imsize'] = imsize
adict['city'] = city
adict['fullname'] = fullname
scipy.io.savemat('./data_mat.mat', adict)
