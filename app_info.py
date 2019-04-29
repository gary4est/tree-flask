from flask import Flask
from subprocess import check_output, STDOUT, CalledProcessError
app = Flask(__name__)

FOOVAR = 'Returning a variable'
@app.route('/')
def hello():
    #return "Hello World!\n bye"
    #return "FOOVAR=%s" % FOOVAR
    return "FOOVAR={}\n".format(FOOVAR)

@app.route('/uptime')
def uptime():
    cmd = ['uptime']
    try:
        result = check_output(cmd, stderr=STDOUT).decode('utf-8')
    except CalledProcessError as e:
        result = e.output.decode('utf-8')
        #result = 'Error 333'
    except FileNotFoundError as e:
        result = 'Command Not Found'
    return result

@app.route('/iostat')
def iostat():
    cmd = ['iostat']
    try:
        result = check_output(cmd, stderr=STDOUT).decode('utf-8')
    except CalledProcessError as e:
        result = e.output.decode('utf-8')
        #result = 'Error 333'
    except FileNotFoundError as e:
        result = 'Command Not Found'
    return result

if __name__ == '__main__':
    app.run(host='0.0.0.0')
