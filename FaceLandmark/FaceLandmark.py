#!/usr/bin/env python3

import os
import cv2
import pygame
import dlib
import numpy as np

def drawFace(part):
    COLOR = (200, 255, 255)
    stroke = 1
    partList = []
    for i in range(0, 17):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, False, partList, stroke)

    partList.clear()
    for i in range(17, 22):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, False, partList, stroke)

    partList.clear()
    for i in range(22, 27):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, False, partList, stroke)

    partList.clear()
    for i in range(27, 31):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, False, partList, stroke)

    partList.clear()
    for i in range(31, 36):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, False, partList, stroke)

    partList.clear()
    for i in range(36, 42):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, True, partList, stroke)

    partList.clear()
    for i in range(42, 48):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, True, partList, stroke)

    partList.clear()
    for i in range(48, 60):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, True, partList, stroke)

    partList.clear()
    for i in range(60, 68):
        partList.append((part(i).x*factor, part(i).y*factor))
    pygame.draw.lines(screen, COLOR, True, partList, stroke)

    return

dataFile = os.path.join(os.getcwd(), 'data/shape_predictor_68_face_landmarks.dat')
BLACK = (0, 0, 0)

factor = 2
dimen = [640, 480]
small = (dimen[0]//factor, dimen[1]//factor)
pygame.init()
screen = pygame.display.set_mode(dimen, pygame.FULLSCREEN)
pygame.display.set_caption('The Red Scout')
running = True
fps = 30
clock = pygame.time.Clock()
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, dimen[0])
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, dimen[1])
cap.set(cv2.CAP_PROP_FPS, fps)
pygame.mouse.set_visible(False)
detector = dlib.get_frontal_face_detector()
predictor = dlib.shape_predictor(dataFile)
alpha = pygame.Surface(dimen)
alpha.set_alpha(255)

while running:
    ret, frame = cap.read()
    if frame is None:
        continue

    screen.fill(BLACK)
    flip = cv2.flip(frame, 1)
    temp = cv2.cvtColor(flip, cv2.COLOR_BGR2RGB)
    temp = cv2.transpose(temp)
    temp = pygame.pixelcopy.make_surface(temp)
    alpha.blit(temp, (0, 0))
    screen.blit(alpha, (0, 0))
    screen.fill((160, 0, 0), special_flags=pygame.BLEND_MULT)

    gray = cv2.resize(flip, small)
    gray = cv2.cvtColor(gray, cv2.COLOR_BGR2GRAY)
    faces = detector(gray)

    for face in faces:
        x1 = face.left()
        y1 = face.top()
        x2 = face.right()
        y2 = face.bottom()
        ww = x2 - x1
        hh = y2 - y1
#        pygame.draw.ellipse(alpha, (255, 0, 0, 128), (x1*factor, y1*factor, ww*factor, hh*factor))

        landmarks = predictor(gray, face)
        drawFace(landmarks.part)

    pygame.display.update()
    clock.tick(fps)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_ESCAPE:
                running = False

pygame.mouse.set_visible(True)
cap.release()
pygame.quit()
