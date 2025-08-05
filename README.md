starknet-devnet --seed=0

Deploy it on DevNet

sncast account import \
    --address=0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691 \
    --type=oz \
    --url=http://127.0.0.1:5050 \
    --private-key=0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9 \
    --add-profile=devnet \
    --silent

sncast --profile=devnet declare \
    --contract-name=HelloStarknet

sncast --profile=devnet deploy \
    --class-hash=0x051515d15b7a64069094e941eee272defd0457e8edb428f08a8a5f0f56c9b9de \
    --salt=0

sncast --profile=devnet invoke \
    --contract-address=0x008678ba0f02854636ce0d1418f36a719dacb4f50244308e415ea8cafc3404e0 \
    --function=register_college \
    --arguments=504753 //should be in felt252 for


sncast --profile=devnet call  
   --contract-address=0x008678ba0f02854636ce0d1418f36a719dacb4f50244308e415ea8cafc3404e0     
   --function=get_college_count
