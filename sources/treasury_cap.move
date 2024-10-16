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

public struct Mint<phantom T> has drop, copy(u64) 

public struct Burn<phantom T> has drop, copy(u64) 

// === Public Mutative === 

public fun new<T>(cap: TreasuryCap<T>, ctx: &mut TxContext): (TreasuryCapV2, MintCap, BurnCap, MetadataCap) {
    let name = type_name::get<T>();

    let mut treasury_cap_v2 = TreasuryCapV2 {
        id: object::new(ctx), 
        name
    };

    dof::add(&mut treasury_cap_v2.id, name, cap);

    let treasury = treasury_cap_v2.id.to_address();

   (
    treasury_cap_v2,
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
    
   let cap = dof::borrow<TypeName, TreasuryCap<T>>(&self.id, self.name);

   cap.update_name(metadata, name);
}

public fun update_symbol<T>(
    self: &TreasuryCapV2, 
    metadata: &mut CoinMetadata<T>, 
    cap: &MetadataCap,
    symbol: ascii::String
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

   let cap = dof::borrow<TypeName, TreasuryCap<T>>(&self.id, self.name);

   cap.update_symbol(metadata, symbol);
}

public fun update_description<T>(
    self: &TreasuryCapV2, 
    metadata: &mut CoinMetadata<T>, 
    cap: &MetadataCap,
    description: string::String
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    let cap = dof::borrow<TypeName, TreasuryCap<T>>(&self.id, self.name);

    cap.update_description(metadata, description);
}

public fun update_icon_url<T>(
    self: &TreasuryCapV2, 
    metadata: &mut CoinMetadata<T>, 
    cap: &MetadataCap,
    url: ascii::String
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    let cap = dof::borrow<TypeName, TreasuryCap<T>>(&self.id, self.name);

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

    let cap = dof::borrow_mut<TypeName, TreasuryCap<T>>(&mut self.id, self.name);

    cap.mint(amount, ctx)
}   

public fun burn<T>(
    self: &mut TreasuryCapV2, 
    cap: &BurnCap,
    coin: Coin<T>
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    emit(Burn<T>(coin.value()));

    let cap = dof::borrow_mut<TypeName, TreasuryCap<T>>(&mut self.id, self.name);

    cap.burn(coin);
}

public fun destroy_burn_cap(cap: BurnCap) {
    let BurnCap { id, .. } = cap;

    id.delete();
}

public fun destroy_mint_cap(cap: MintCap) {
    let MintCap { id, .. } = cap;

    id.delete();
}

public fun destroy_metadata_cap(cap: MetadataCap) {
    let MetadataCap { id, .. } = cap;

    id.delete();
}

// === Public View Functions === 

public fun total_supply<T>(self: &TreasuryCapV2): u64 {
    let cap = dof::borrow<TypeName, TreasuryCap<T>>(&self.id, self.name);      

    cap.total_supply()
}

// === Method Aliases ===  

public use fun destroy_burn_cap as BurnCap.destroy;
public use fun destroy_mint_cap as MintCap.destroy;
public use fun destroy_metadata_cap as MetadataCap.destroy;