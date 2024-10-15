module treasury_cap_v2::treasury_cap;
// === Imports === 

use std::{
    ascii,
    string,
    type_name::{Self, TypeName}
};

use sui::{
    event::emit,
    dynamic_object_field as dof,
    coin::{TreasuryCap, CoinMetadata, Coin},
};

// === Errors === 

#[error]
const EInvalidCap: vector<u8> = b"The cap does not match the treasury.";

// === Structs === 

public struct BurnCap has key, store {
    id: UID,
    treasury: address
}

public struct MintCap has key, store {
    id: UID,
    treasury: address
}

public struct MetadataCap has key, store {
    id: UID,
    treasury: address
}

public struct TreasuryCapV2 has key, store {
    id: UID,
    name: TypeName
}

// === Events ===  

public struct Mint<phantom CoinType> has drop, copy(u64) 

public struct Burn<phantom CoinType> has drop, copy(u64) 

// === Public Mutative === 

public fun new<CoinType>(cap: TreasuryCap<CoinType>, ctx: &mut TxContext): (TreasuryCapV2, MintCap, BurnCap, MetadataCap) {
    let name = type_name::get<CoinType>();

    let mut memez_cap = TreasuryCapV2 {
        id: object::new(ctx), 
        name
    };

    dof::add(&mut memez_cap.id, name, cap);

    let treasury = memez_cap.id.to_address();

   (
    memez_cap,
    MintCap {
        id: object::new(ctx),
        treasury
    },
    BurnCap {
        id: object::new(ctx),
        treasury
    },
    MetadataCap {
        id: object::new(ctx),
        treasury
    }
   )
}

public fun update_name<T>(
    self: &TreasuryCapV2, 
    metadata: &mut CoinMetadata<T>, 
    cap: &MetadataCap,
    name: string::String
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);
   let cap = dof::borrow<TypeName ,TreasuryCap<T>>(&self.id, type_name::get<T>());

   cap.update_name(metadata, name);
}

public fun update_symbol<T>(
    self: &TreasuryCapV2, 
    metadata: &mut CoinMetadata<T>, 
    cap: &MetadataCap,
    symbol: ascii::String
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

   let cap = dof::borrow<TypeName ,TreasuryCap<T>>(&self.id, type_name::get<T>());

   cap.update_symbol(metadata, symbol);
}

public fun update_description<T>(
    self: &TreasuryCapV2, 
    metadata: &mut CoinMetadata<T>, 
    cap: &MetadataCap,
    description: string::String
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    let cap = dof::borrow<TypeName ,TreasuryCap<T>>(&self.id, type_name::get<T>());

    cap.update_description(metadata, description);
}

public fun update_icon_url<T>(
    self: &TreasuryCapV2, 
    metadata: &mut CoinMetadata<T>, 
    cap: &MetadataCap,
    url: ascii::String
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    let cap = dof::borrow<TypeName ,TreasuryCap<T>>(&self.id, type_name::get<T>());

    cap.update_icon_url(metadata, url);
}

public fun mint<T>(
    self: &mut TreasuryCapV2, 
    cap: &MintCap,
    amount: u64,
    ctx: &mut TxContext
): Coin<T> {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    emit(Mint<T>(amount));

    let cap = dof::borrow_mut<TypeName ,TreasuryCap<T>>(&mut self.id, type_name::get<T>());

    cap.mint(amount, ctx)
}   

public fun burn<T>(
    self: &mut TreasuryCapV2, 
    cap: &BurnCap,
    coin: Coin<T>
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    emit(Burn<T>(coin.value()));

    let cap = dof::borrow_mut<TypeName ,TreasuryCap<T>>(&mut self.id, type_name::get<T>());

    cap.burn(coin);
}

public fun destroy_burn_cap(cap: BurnCap) {
    let BurnCap { id, .. } = cap;

    object::delete(id);
}

public fun destroy_mint_cap(cap: MintCap) {
    let MintCap { id, .. } = cap;

    object::delete(id);
}

public fun destroy_metadata_cap(cap: MetadataCap) {
    let MetadataCap { id, .. } = cap;

    object::delete(id);
}

// === Public View Functions === 

public fun total_supply<T>(self: &TreasuryCapV2): u64 {
    let cap = dof::borrow<TypeName ,TreasuryCap<T>>(&self.id, type_name::get<T>());      

    cap.total_supply()
}

// === Method Aliases ===  

public use fun destroy_burn_cap as BurnCap.destroy;
public use fun destroy_mint_cap as MintCap.destroy;
public use fun destroy_metadata_cap as MetadataCap.destroy;