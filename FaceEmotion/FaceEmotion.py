#!/usr/bin/env python3

import cv2
import os
import pygame
import dlib
import numpy as np

def softmax(x):
    x = x.reshape(-1)
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=0)


dataPath = os.path.join(os.getcwd(), 'data')

cap = cv2.VideoCapture(0)
dimen1 = (1280, 720)
dimen2 = (300, 300)
dimen3 = (227, 227)
dimen4 = (64, 64)
factor = 4
small = (dimen1[0]//factor, dimen1[1]//factor)

input_shape = (1, 1, dimen4[0], dimen4[1])
fps = 30
running = True

cap.set(cv2.CAP_PROP_FRAME_WIDTH, dimen1[0])
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, dimen1[1])
cap.set(cv2.CAP_PROP_FPS, fps)

emoModel = dataPath + "/model.onnx"
emoNet = cv2.dnn.readNetFromONNX(emoModel)
emoNet.setPreferableTarget(cv2.dnn.DNN_TARGET_OPENCL)

emotion_table = {'neutral':0, 'happiness':1, 'surprise':2, 'sadness':3, 'anger':4, 'disgust':5, 'fear':6, 'contempt':7}
emotion_keys = list(emotion_table.keys())
detector = dlib.get_frontal_face_detector()

pygame.init()
pygame.font.init()
screen = pygame.display.set_mode(dimen1, pygame.HWSURFACE)
pygame.display.set_caption('Face detection')
font = pygame.font.SysFont("arial", 12)
clock = pygame.time.Clock()
THRESHOLD = 0.8
pygame.mouse.set_visible(False)

while running:
    ret, frame = cap.read()
    if frame is None:
        continue

    screen.fill((0, 0, 0))
    flip = cv2.flip(frame, 1)
    temp = cv2.cvtColor(flip, cv2.COLOR_BGR2RGB)
    temp = cv2.transpose(temp)
    temp = pygame.pixelcopy.make_surface(temp)
    screen.blit(temp, [0, 0])

    gray = cv2.resize(flip, small)
    gray = cv2.cvtColor(gray, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)

    for face in faces:
        x1 = face.left()*factor
        y1 = face.top()*factor
        x2 = face.right()*factor
        y2 = face.bottom()*factor
        ww = x2 - x1
        hh = y2 - y1
        pygame.draw.rect(screen, (255, 255, 255), (x1, y1, ww, hh), 2)
        small_face = flip[max(0, y1):min(y2, flip.shape[0]-1), max(0, x1):min(x2, flip.shape[1]-1)]
        small_face = cv2.resize(small_face, dimen4, cv2.INTER_AREA)
        small_face = cv2.cvtColor(small_face, cv2.COLOR_BGR2GRAY)
        img_data = np.array(small_face)
        img_data = np.resize(img_data, input_shape).astype(np.float32)
        emoNet.setInput(img_data)
        result = emoNet.forward()
        out = softmax(result)
        out = np.squeeze(out)
        classes = np.argsort(out)[::-1]
        emotion = emotion_keys[classes[0]]
        label = "{}".format(emotion)
        text = font.render(label, True, (255, 0, 0))
        screen.blit(text, (x1 + 5, y1 + 3))

    pygame.display.update()
    clock.tick(fps)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False

pygame.mouse.set_visible(True)
pygame.quit()
cap.release()
