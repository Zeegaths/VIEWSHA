import React from "react";
import Footer from "./Footer";
import Header from "./Header";
import { StarknetProvider } from "../provider/starknet-provider";

const Layout = ({ children }) => {
  return (
    <>
      <Header />
      <StarknetProvider>
        {children}
      </StarknetProvider>
      <Footer />

    </>
  );
};

export default Layout;
