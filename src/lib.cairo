use core::starknet::ContractAddress;

#[starknet::interface]
pub trait IOrderTracking<TContractState> {
    fn place_order(
        ref self: TContractState,
        order_id: felt252,
        product: felt252,
        quantity: u64,
        seller: ContractAddress
    );
    fn get_order(self: @TContractState, order_id: felt252) -> OrderTracking::Order;
    fn get_total_orders(self: @TContractState) -> u128;
    fn confirm_order(ref self: TContractState, order_id: felt252);
}

#[starknet::contract]
mod OrderTracking {
    use core::starknet::{ContractAddress, get_caller_address, storage_access};
    use core::starknet::storage::{Map};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        orders: Map::<felt252, Order>,
        total_orders: u128,
        order_status: Map<felt252, Status>,
    }
    #[derive(Drop, Serde, starknet::Store, Copy)]
    pub enum Status {
        Confirmed,
        InTransit,
        Delivered,
        Cancelled,
    }

    #[derive(Drop, Serde, Copy, starknet::Store)]
    pub struct Order {
        order_id: felt252,
        product: felt252,
        quantity: u64,
        placed_by: ContractAddress,
        seller: ContractAddress,
        status: Status,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OrderPlaced: OrderPlaced,
        // OrderCompleted: OrderCompleted,
    }
    #[derive(Drop, starknet::Event)]
    struct OrderPlaced {
        #[key]
        order_id: felt252,
        product: felt252,
        quantity: u64,
    }


    #[constructor]
    fn constructor(ref self: ContractState) {
        self.total_orders.write(0);
        self.owner.write(get_caller_address());
    }

    // Public functions inside an impl block
    #[abi(embed_v0)]
    impl OrderTracking of super::IOrderTracking<ContractState> {
        fn place_order(
            ref self: ContractState,
            order_id: felt252,
            product: felt252,
            quantity: u64,
            seller: ContractAddress
        ) {
            let caller = get_caller_address();
            let mut order = Order {
                order_id,
                product,
                quantity,
                placed_by: caller,
                seller: seller,
                status: Status::Confirmed
            };
            // let oders = self.orders.read(order_id);
            self.orders.write(order_id, order);
            self.total_orders.write(self.total_orders.read() + 1);
            self.emit(OrderPlaced { order_id, product, quantity });
        }

        fn get_order(self: @ContractState, order_id: felt252) -> Order {
            self.orders.read(order_id)
        }

        fn get_total_orders(self: @ContractState) -> u128 {
            self.total_orders.read()
        }

        fn confirm_order(ref self: ContractState, order_id: felt252) {
            let mut order = self.orders.read(order_id);
            order.status = Status::Delivered;
            self.orders.write(order_id, order);
        }
    }
}
