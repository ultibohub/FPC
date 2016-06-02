
uses winsock;

Type
  PHostEntry = PHostEnt;
  PNetEntry = PNetEnt;
  PServEntry = PServEnt;

Function GetDNSError : Longint;

begin
  GetDNSError:=WSAGetLastError;
end;

Function InitResolve : Boolean;

begin
  Result:=True;
end;

Function FinalResolve : Boolean;

begin
  Result:=True;
end;
