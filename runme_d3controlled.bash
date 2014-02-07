#!/bin/bash

killall sclang
killall scsynth



echo ""
echo ""
echo "*************************************"
echo "           UVA - Momentum"
echo ""
echo "      sound system initialising"
echo ""
echo "       it takes about a minute"
echo ""
echo " SuperCollider system by Dan Stowell"
echo "*************************************"
echo ""
echo ""

sleep 20

/Applications/SuperCollider365/SuperCollider.app/Contents/Resources/sclang scrunall_d3controlled.scd




