#[test_only]
module treasury_cap_v2::treasury_cap_tests;

use sui::{
    test_scenario as ts, 
    test_utils::{assert_eq, destroy},
    coin::{Self, TreasuryCap, CoinMetadata}
};

use treasury_cap_v2::{ 
    treasury_cap,
    aptos::{Self, APTOS},
};

const ADMIN: address = @0xdead;

public struct ETH has drop()

#[test]
fun test_end_to_end() {
    let mut scenario = ts::begin(ADMIN); 

    aptos::init_for_testing(scenario.ctx());

    scenario.next_tx(ADMIN);

    let cap = scenario.take_from_sender<TreasuryCap<APTOS>>();
    let mut metadata = scenario.take_shared<CoinMetadata<APTOS>>(); 

    assert_eq(metadata.get_decimals(), 9);
    assert_eq(metadata.get_symbol(), b"APT".to_ascii_string());
    assert_eq(metadata.get_name(), b"Aptos".to_string());
    assert_eq(metadata.get_description(), b"The second best move chain".to_string());
    assert_eq(metadata.get_icon_url(), option::none());
    assert_eq(cap.total_supply(), 0);

    let (mut treasury_cap_v2, mint_cap, burn_cap, metadata_cap, ) = treasury_cap::new(cap, scenario.ctx());

    let aptos_coin = treasury_cap_v2.mint<APTOS>(&mint_cap, 100, scenario.ctx());

    let effects = scenario.next_tx(ADMIN);

    assert_eq(effects.num_user_events(), 1);

    assert_eq(treasury_cap_v2.total_supply<APTOS>(), 100);
    assert_eq(aptos_coin.value(), 100);

    treasury_cap_v2.burn<APTOS>(&burn_cap, aptos_coin);

    let effects = scenario.next_tx(ADMIN);

    assert_eq(effects.num_user_events(), 1);

    assert_eq(treasury_cap_v2.total_supply<APTOS>(), 0);

    let treasury_address = object::id(&treasury_cap_v2).to_address();

    assert_eq(treasury_address, mint_cap.treasury());
    assert_eq(treasury_address, burn_cap.treasury());
    assert_eq(treasury_address, metadata_cap.treasury());
    
    treasury_cap_v2.update_name<APTOS>(&mut metadata,&metadata_cap, b"Aptos V2".to_string()); 
    treasury_cap_v2.update_symbol<APTOS>(&mut metadata,&metadata_cap, b"APT2".to_ascii_string()); 
    treasury_cap_v2.update_description<APTOS>(&mut metadata,&metadata_cap, b"Aptos V2 is the best".to_string());
    treasury_cap_v2.update_icon_url<APTOS>(&mut metadata,&metadata_cap, b"https://aptos.dev/logo.png".to_ascii_string());

    assert_eq(metadata.get_name(), b"Aptos V2".to_string());
    assert_eq(metadata.get_symbol(), b"APT2".to_ascii_string());
    assert_eq(metadata.get_description(), b"Aptos V2 is the best".to_string());
    assert_eq(metadata.get_icon_url().borrow().inner_url(), b"https://aptos.dev/logo.png".to_ascii_string());

    mint_cap.destroy();
    burn_cap.destroy();
    metadata_cap.destroy();

    destroy(treasury_cap_v2);
    destroy(metadata);
    destroy(scenario);
}

#[test] 
#[expected_failure(abort_code = treasury_cap::EInvalidCap)]
fun test_invalid_metadata_cap() {
    let mut scenario = ts::begin(ADMIN); 

    aptos::init_for_testing(scenario.ctx());

    scenario.next_tx(ADMIN);

    let cap = scenario.take_from_sender<TreasuryCap<APTOS>>();
    let mut aptos_metadata = scenario.take_shared<CoinMetadata<APTOS>>(); 

    let eth_cap = coin::create_treasury_cap_for_testing<ETH>(scenario.ctx());

    let (aptos_treasury_cap_v2, aptos_mint_cap, aptos_burn_cap, aptos_metadata_cap, ) = treasury_cap::new(cap, scenario.ctx());

    let (eth_treasury_cap_v2, eth_mint_cap, eth_burn_cap, eth_metadata_cap, ) = treasury_cap::new(eth_cap, scenario.ctx());

    aptos_treasury_cap_v2.update_name<APTOS>(&mut aptos_metadata,&eth_metadata_cap, b"Aptos V2".to_string()); 

    destroy(scenario); 
    destroy(aptos_metadata);
    destroy(aptos_treasury_cap_v2);
    destroy(eth_treasury_cap_v2);
    aptos_mint_cap.destroy();
    aptos_burn_cap.destroy();
    aptos_metadata_cap.destroy();
    eth_mint_cap.destroy();
    eth_burn_cap.destroy();
    eth_metadata_cap.destroy();
}

#[test] 
#[expected_failure(abort_code = treasury_cap::EInvalidCap)]
fun test_invalid_mint_cap() {
    let mut scenario = ts::begin(ADMIN); 

    aptos::init_for_testing(scenario.ctx());

    scenario.next_tx(ADMIN);

    let cap = scenario.take_from_sender<TreasuryCap<APTOS>>();

    let eth_cap = coin::create_treasury_cap_for_testing<ETH>(scenario.ctx());

    let (mut aptos_treasury_cap_v2, aptos_mint_cap, aptos_burn_cap, aptos_metadata_cap, ) = treasury_cap::new(cap, scenario.ctx());

    let (eth_treasury_cap_v2, eth_mint_cap, eth_burn_cap, eth_metadata_cap, ) = treasury_cap::new(eth_cap, scenario.ctx());

    let aptos_coin = aptos_treasury_cap_v2.mint<APTOS>(&eth_mint_cap, 100, scenario.ctx());

    destroy(scenario); 
    destroy(aptos_coin);
    destroy(aptos_treasury_cap_v2);
    destroy(eth_treasury_cap_v2);
    aptos_mint_cap.destroy();
    aptos_burn_cap.destroy();
    aptos_metadata_cap.destroy();
    eth_mint_cap.destroy();
    eth_burn_cap.destroy();
    eth_metadata_cap.destroy();
}

#[test] 
#[expected_failure(abort_code = treasury_cap::EInvalidCap)]
fun test_invalid_burn_cap() {
    let mut scenario = ts::begin(ADMIN); 

    aptos::init_for_testing(scenario.ctx());

    scenario.next_tx(ADMIN);

    let cap = scenario.take_from_sender<TreasuryCap<APTOS>>();

    let eth_cap = coin::create_treasury_cap_for_testing<ETH>(scenario.ctx());

    let (mut aptos_treasury_cap_v2, aptos_mint_cap, aptos_burn_cap, aptos_metadata_cap, ) = treasury_cap::new(cap, scenario.ctx());

    let (eth_treasury_cap_v2, eth_mint_cap, eth_burn_cap, eth_metadata_cap, ) = treasury_cap::new(eth_cap, scenario.ctx());

    let aptos_coin = aptos_treasury_cap_v2.mint<APTOS>(&aptos_mint_cap, 100, scenario.ctx());

    aptos_treasury_cap_v2.burn<APTOS>(&eth_burn_cap, aptos_coin);

    destroy(scenario); 
    destroy(aptos_treasury_cap_v2);
    destroy(eth_treasury_cap_v2);
    aptos_mint_cap.destroy();
    aptos_burn_cap.destroy();
    aptos_metadata_cap.destroy();
    eth_mint_cap.destroy();
    eth_burn_cap.destroy();
    eth_metadata_cap.destroy();
}