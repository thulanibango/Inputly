import express from "express";
const app = express();


app.get("/", (req, res) => {
    res.send("Hello from Inputly!").status(200);
});


export default app;
