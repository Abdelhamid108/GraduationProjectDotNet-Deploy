import graphOverlay from "./graph overlay.png";

const AuthBackground = () => {
  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 0,
      }}
    >
      {/* Linear gradient base */}
      <div
        style={{
          position: "absolute",
          inset: 0,
          background: "linear-gradient(to bottom, #1B8CC0 0%, #19156C 100%)",
        }}
      />
      {/* Graph overlay - right half only */}
      <div
        style={{
          position: "absolute",
          top: 0,
          right: 0,
          bottom: 0,
          width: "50%",
          backgroundImage: `url(${graphOverlay})`,
          backgroundSize: "cover",
          backgroundPosition: "left center",
          backgroundRepeat: "no-repeat",
          opacity: 0.25,
        }}
      />
    </div>
  );
};

export default AuthBackground;
