#!/bin/sh
HOME_DIR=/home/commaai
PAYCLIENT_DIR=$HOME_DIR/Klas_NanWei
PAYCLIENT_PY_PG=Klas_V1_1_3.py

if [ -r "/dev/ttyS0" ]; then
    chmod 777 /dev/ttyS0
fi

export PATH=/usr/local/cuda-9.0/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda-9.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

export PYTHONPATH=$HOME_DIR/.local/lib/python3.5/site-packages:$PYTHONPATH

QTDIR=/usr/local/Qt-5.10.1
export PATH=$QTDIR/bin:$PATH
export LD_LIBRARY_PATH=$QTDIR/lib:$LD_LIBRARY_PATH
export QML2_IMPORT_APTH=$QTDIR/qml
export QT_QPA_PLATFORM_PLUGIN_PATH=$QTDIR/plugins

if [ -x "/usr/bin/compiz" ]; then
    compiz &
fi

cd $PAYCLIENT_DIR
python3 $PAYCLIENT_PY_PG

exit 0
