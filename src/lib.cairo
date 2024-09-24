use core::starknet::ContractAddress;

#[starknet::interface]
pub trait IOrderTracking<TContractState> {
    fn place_order(
        ref self: TContractState,
        order_id: felt252,
        product: felt252,
        quantity: u64,
        price: u64,
        seller: ContractAddress
    );
    fn get_order(self: @TContractState, order_id: felt252) -> OrderTracking::Order;
    fn get_total_orders(self: @TContractState) -> u128;
    fn confirm_order(ref self: TContractState, order_id: felt252);
    fn ship_order(ref self: TContractState, order_id: felt252);
    fn cancel_order(ref self: TContractState, order_id: felt252, reason: felt252, images_uri: felt252);
    fn refund_user(ref self: TContractState, order_id: felt252);
}

#[starknet::contract]
mod OrderTracking {
    use core::starknet::{ContractAddress, get_caller_address, contract_address_const, storage_access};
    use core::starknet::storage::{Map};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

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
        price: u64,
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
            price: u64,
            seller: ContractAddress
        ) {
            let caller = get_caller_address();
            let contract_address = contract_address_const();
            self._transfer_from(caller, contract_address, price);
            let mut order = Order {
                order_id,
                product,
                quantity,
                price,
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

        fn ship_order(ref self: ContractState, order_id: felt252) {
            let mut order = self.orders.read(order_id);
            let caller = get_caller_address();
            assert( caller == order.seller, 'You are not the seller');
            order.status = Status::InTransit;
        }

         fn confirm_order(ref self: ContractState, order_id: felt252) {
            let mut order = self.orders.read(order_id);
            self._transfer(order.seller, order.price);
            order.status = Status::Delivered;
            self.orders.write(order_id, order);
        }


        fn cancel_order(ref self: ContractState, order_id: felt252, reason: felt252, images_uri: felt252) {
            let mut order = self.orders.read(order_id);
            order.status = Status::Cancelled;

        }
        fn refund_user(ref self: ContractState, order_id: felt252) {
            let mut order = self.orders.read(order_id);
            // assert(order.status == Status::Cancelled, 'order needs to be cancelled');
            self._transfer(order.placed_by, order.price);
        }
    }


    #[generate_trait]
    impl ERC20Impl of ERC20Trait {
        fn _transfer_from(ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u64) {
            let eth_dispatcher = IERC20Dispatcher {
                contract_address: contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>() // STRK token Contract Address
            };
            assert(eth_dispatcher.balance_of(sender) >= amount.into(), 'insufficient funds');

            // eth_dispatcher.approve(validator_contract_address, amount.into()); This is wrong as it is the validator contract trying to approve itself
            let success = eth_dispatcher.transfer_from(sender, recipient, amount.into());
            assert(success, 'ERC20 transfer_from fail!');
        }

        fn _transfer(ref self: ContractState, recipient: ContractAddress, amount: u64) {
            let eth_dispatcher = IERC20Dispatcher {
                contract_address: contract_address_const::<0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d>() // STRK token Contract Address
            };
            let success = eth_dispatcher.transfer(recipient, amount.into());
            assert(success, 'ERC20 transfer fail!');
        }
    }

}
