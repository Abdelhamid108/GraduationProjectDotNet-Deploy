import { BrowserRouter, Route, Routes } from "react-router-dom";
import "./App.css";
import CheckCode from "./pages/CheckCode";
import ForgotPassword from "./pages/ForgotPassword";
import History from "./pages/History";
import Home from "./pages/Home";
import Instructions from "./pages/Instructions";
import Letters from "./pages/Letters";
import Login from "./pages/Login";
import ResetPassword from "./pages/ResetPassword";
import Signup from "./pages/Signup";
import { Toaster } from "sonner";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/" element={<Home />} />
        <Route path="/letters" element={<Letters />} />
        <Route path="/history" element={<History />} />
        <Route path="/instructions" element={<Instructions />} />

        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password" element={<ResetPassword />} />
        <Route path="/check-code" element={<CheckCode />} />
      </Routes>
      <Toaster richColors position="top-center" />
    </BrowserRouter>
  );
}

export default App;
