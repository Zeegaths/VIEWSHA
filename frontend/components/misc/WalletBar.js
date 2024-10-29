"use client";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import { useMemo } from "react";


function WalletConnected() {
  const { address } = useAccount();
  const { disconnect } = useDisconnect();

  const shortenedAddress = useMemo(() => {
    if (!address) return "";
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }, [address]);

  return (
    <button onClick={() => disconnect()} className="text-saBluelite bg-orange-500 rounded-md border border-saOrange hover:bg-saBluelite hover:border-saBluelite transition-all duration-300 hover:text-white-500 text-sm px-5 py-2 flex items-center gap-1.5">Disconnect
      <span className="font-medium">{shortenedAddress}</span>
    </button>
  );
}

function ConnectWallet() {
  const { connectors, connect } = useConnect();

  return (
    <>
      {connectors.map((connector) => {
        return (
          <button
            key={connector.id}
            onClick={async () => connector.available() ? connect({ connector }) : null}
            className="font-medium tracking-wide py-2 px-5 sm:px-8 border border-orange-500 text-orange-500 bg-white-500 outline-none rounded-l-full rounded-r-full capitalize hover:bg-orange-500 hover:text-white-500 transition-all hover:shadow-orange"
          >
            {connector.id}
          </button>
        );
      })}
    </>
  );
}

export default function WalletBar() {
  const { address } = useAccount();

  return address ? <WalletConnected /> : <ConnectWallet />;
}
