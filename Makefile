all    :; source .env && dapp --use solc:0.6.7 build
clean  :; dapp clean
test   :; dapp test
deploy :; dapp create Pve
