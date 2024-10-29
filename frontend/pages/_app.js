import "../styles/tailwind.css";
import "../styles/slick.css";
import { StarknetProvider } from "../components/provider/starknet-provider";

function MyApp({ Component, pageProps }) {
  return (
    <StarknetProvider>
      <Component {...pageProps} />
    </StarknetProvider>
  );
}

export default MyApp;
