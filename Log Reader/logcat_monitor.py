from tkinter import *
from tkinter import messagebox
import threading
import subprocess

THREAD = None
PROCESS = None


def read_log(process):
    for line in iter(process.stdout.readline, b""):
        print(line.decode(), end=''),


def read_log_thread():
    """ Button-Event-Handler starting the log reading. """
    global THREAD
    global PROCESS
    PROCESS = subprocess.Popen(["adb logcat"], shell=False, stdout=subprocess.PIPE)
    THREAD = threading.Thread(target=read_log, args=(PROCESS,))
    THREAD.start()


def hello():
    messagebox.showinfo(message='Hello.')


def main():
    root = Tk()
    Button(master=root, text='Start reading', command=read_log_thread).pack()
    buttonX = Button(master=root, text='Hello', command=hello).pack()
    root.mainloop()
    if PROCESS and PROCESS.poll():
        PROCESS.terminate()
    THREAD.join()

if __name__ == '__main__':
    main()