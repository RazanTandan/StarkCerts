use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct College {
    pub id: u32,
    pub name: felt252,
    pub admin: ContractAddress,
    pub is_active: bool,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Certificate {
    pub id: u256,
    pub student: ContractAddress,
    pub college_id: u32,
    pub degree: felt252,
    pub issue_date: u64,
    pub is_valid: bool,
}

#[starknet::interface]
pub trait ICertificateSystem<TContractState> {
    // College functions
    fn register_college(ref self: TContractState, name: felt252) -> u32;
    fn get_college(self: @TContractState, college_id: u32) -> College;
    
    // Certificate functions
    fn issue_certificate(
        ref self: TContractState, 
        student: ContractAddress, 
        degree: felt252
    ) -> u256;
    fn get_certificate(self: @TContractState, cert_id: u256) -> Certificate;
    fn verify_certificate(self: @TContractState, cert_id: u256) -> bool;
    
    // View functions
    fn get_student_certificates(self: @TContractState, student: ContractAddress) -> Array<u256>;
    fn get_college_count(self: @TContractState) -> u32;
    fn get_certificate_count(self: @TContractState) -> u256;
}