#!/usr/bin/env python3

import numpy as np
import os
import cv2
import dlib
import pygame
from keras.models import model_from_json
from keras.preprocessing import image
from os.path import expanduser

BLACK = (0, 0, 0)
dataPath = os.path.join(os.getcwd(), 'data')
userPath = expanduser("~")
userPath = userPath + "\\Desktop\\"

factor = 2
dimen = (640, 480)
small = (dimen[0]//factor, dimen[1]//factor)
out_dimen = (300, 300)
pygame.init()
pygame.font.init()
screen = pygame.display.set_mode(dimen, pygame.FULLSCREEN | pygame.HWSURFACE)
pygame.display.set_caption('The Red Scout')
font = pygame.font.SysFont('arial', 24)
running = True
checking = False
fps = 30
clock = pygame.time.Clock()
detector = dlib.get_frontal_face_detector()
classes = ['Patriotic', 'Unpatriotic']
status = ""

cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, dimen[0])
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, dimen[1])
cap.set(cv2.CAP_PROP_FPS, fps)

json_file = open(dataPath + '/faceModel.json', 'r')
loaded_model_json = json_file.read()
json_file.close()
loaded_model = model_from_json(loaded_model_json)
loaded_model.load_weights(dataPath + '/faceModel.h5')

loaded_model.summary()
print(loaded_model.layers[0].input_shape)

while running:
    ret, frame = cap.read()
    if frame is None:
        continue

    screen.fill(BLACK)
    flip = cv2.flip(frame, 1)
    temp = cv2.cvtColor(flip, cv2.COLOR_BGR2RGB)
    temp = cv2.transpose(temp)
    temp = pygame.pixelcopy.make_surface(temp)
    screen.blit(temp, (0, 0))

    small_face = cv2.resize(flip, small)
    gray = cv2.cvtColor(small_face, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)

    max_area = 0
    max_face = small_face

    for face in faces:
        x1 = face.left()
        y1 = face.top()
        x2 = face.right()
        y2 = face.bottom()
        area = (x2 - x1) * (y2 - y1)
        if area > max_area:
            max_area = area
#            max_face = small_face[x1:x2, y1:y2]
            max_face = small_face[y1:y2, x1:x2]

    if max_area > 0:
        pygame.draw.rect(screen, (255, 0, 0), (x1*factor, y1*factor, (x2-x1)*factor, (y2-y1)*factor), 1)
        if checking:
            my_face = flip[y1 * factor:y2 * factor, x1 * factor:x2 * factor]
            my_face = cv2.resize(my_face, out_dimen)
            my_face = cv2.cvtColor(my_face, cv2.COLOR_BGR2RGB)
            my_face = cv2.transpose(my_face)
            my_face = pygame.pixelcopy.make_surface(my_face)

            test_image = cv2.resize(max_face, (32, 32))
            test_image = (test_image[...,::-1].astype(np.float32)) / 255.0
            test_image = np.expand_dims(test_image, axis=0)
            result = loaded_model.predict_classes(test_image)
            status = classes[result[0]]
            file_name = userPath + status + str(pygame.time.get_ticks()) + ".png"
            pygame.image.save(my_face, file_name)

            checking = False
    elif checking:
        checking = False

    text = font.render(status, True, (255, 255, 255))
    screen.blit(text, (20, 20))
    pygame.display.update()
    clock.tick(fps)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False
        elif event.type == pygame.MOUSEBUTTONDOWN:
            status = ""
            checking = True

pygame.quit()
cap.release()
