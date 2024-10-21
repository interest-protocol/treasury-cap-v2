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

#[error]
const ECapAlreadyCreated: vector<u8> = b"The cap has already been created.";

#[error]
const EBurnCapIsIndestructible: vector<u8> = b"The burn cap is indestructible.";

// === Structs === 

public struct CapWitness has drop {
    treasury: address,
    name: TypeName,
    mint_created: bool,
    burn_created: bool,
    metadata_created: bool
}

public struct BurnCap has key, store {
    id: UID,
    treasury: address,
    indestructible: bool,
    name: TypeName
}

public struct MintCap has key, store {
    id: UID,
    treasury: address,
    name: TypeName
}

public struct MetadataCap has key, store {
    id: UID,
    treasury: address,
    name: TypeName
}

public struct TreasuryCapV2 has key, store {
    id: UID,
    name: TypeName
}

// === Events ===  

public struct Mint has drop, copy(TypeName, u64) 

public struct Burn has drop, copy(TypeName, u64) 

public struct DestroyMintCap has drop, copy(TypeName)

public struct DestroyBurnCap has drop, copy(TypeName)

public struct DestroyMetadataCap has drop, copy(TypeName)

// === Public Mutative === 

public fun new<T>(cap: TreasuryCap<T>, ctx: &mut TxContext): (TreasuryCapV2, CapWitness) {
    let name = type_name::get<T>();

    let mut treasury_cap_v2 = TreasuryCapV2 {
        id: object::new(ctx), 
        name
    };

    dof::add(&mut treasury_cap_v2.id, name, cap);

    let treasury = treasury_cap_v2.id.to_address();

   (
    treasury_cap_v2,
    CapWitness { 
        treasury, 
        name, 
        mint_created: false, 
        burn_created: false, 
        metadata_created: false 
    }
   )
}

public fun generate_mint_cap(witness: &mut CapWitness, ctx: &mut TxContext): MintCap {
    assert!(!witness.mint_created, ECapAlreadyCreated);
    witness.mint_created = true;

    MintCap {
        id: object::new(ctx),
        treasury: witness.treasury,
        name: witness.name
    }
}

public fun generate_burn_cap(witness: &mut CapWitness, indestructible: bool, ctx: &mut TxContext): BurnCap {
    assert!(!witness.burn_created, ECapAlreadyCreated);
    witness.burn_created = true;
    
    BurnCap {
        id: object::new(ctx),
        treasury: witness.treasury,
        name: witness.name,
        indestructible
    }
}

public fun generate_metadata_cap(witness: &mut CapWitness, ctx: &mut TxContext): MetadataCap {
    assert!(!witness.metadata_created, ECapAlreadyCreated);
    witness.metadata_created = true;
    
    MetadataCap {
        id: object::new(ctx),
        treasury: witness.treasury,
        name: witness.name
    }
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

    emit(Mint(self.name, amount));

    let cap = dof::borrow_mut<TypeName, TreasuryCap<T>>(&mut self.id, self.name);

    cap.mint(amount, ctx)
}   

public fun burn<T>(
    self: &mut TreasuryCapV2, 
    cap: &BurnCap,
    coin: Coin<T>
) {
    assert!(cap.treasury == self.id.to_address(), EInvalidCap);

    emit(Burn(self.name, coin.value()));

    let cap = dof::borrow_mut<TypeName, TreasuryCap<T>>(&mut self.id, self.name);

    cap.burn(coin);
}

public fun destroy_burn_cap(cap: BurnCap) {
    assert!(!cap.indestructible, EBurnCapIsIndestructible);

    let BurnCap { id, name, .. } = cap;

    emit(DestroyBurnCap(name));

    id.delete();
}

public fun destroy_mint_cap(cap: MintCap) {
    let MintCap { id, name, .. } = cap;

    emit(DestroyMintCap(name));

    id.delete();
}

public fun destroy_metadata_cap(cap: MetadataCap) {
    let MetadataCap { id, name, .. } = cap;

    emit(DestroyMetadataCap(name));

    id.delete();
}

// === Public View Functions === 

public fun total_supply<T>(self: &TreasuryCapV2): u64 {
    let cap = dof::borrow<TypeName, TreasuryCap<T>>(&self.id, self.name);      

    cap.total_supply()
}

public fun mint_cap_treasury(cap: &MintCap): address {
    cap.treasury
}

public fun burn_cap_treasury(cap: &BurnCap): address {
    cap.treasury
}

public fun metadata_cap_treasury(cap: &MetadataCap): address {
    cap.treasury
}

public fun mint_cap_name(cap: &MintCap): TypeName {
    cap.name
}

public fun burn_cap_name(cap: &BurnCap): TypeName {
    cap.name
}

public fun metadata_cap_name(cap: &MetadataCap): TypeName {
    cap.name
}

// === Method Aliases ===  

public use fun destroy_burn_cap as BurnCap.destroy;
public use fun destroy_mint_cap as MintCap.destroy;
public use fun destroy_metadata_cap as MetadataCap.destroy;

public use fun mint_cap_treasury as MintCap.treasury;
public use fun burn_cap_treasury as BurnCap.treasury;
public use fun metadata_cap_treasury as MetadataCap.treasury;

public use fun mint_cap_name as MintCap.name;
public use fun burn_cap_name as BurnCap.name;
public use fun metadata_cap_name as MetadataCap.name;