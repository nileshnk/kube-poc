import express, { Request, Response } from "express";
const app = express();

app.get("/", (req: Request, res: Response) => {
  res.send("User Management!");
});

app.get("/version", (req: Request, res: Response) => {
  res.send("2.2\n");
});

const PORT = 5101;

app.listen(PORT, () => {
  console.log("listening on port", PORT);
});
