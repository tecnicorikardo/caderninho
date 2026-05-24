import { createContext, useContext } from "react";

type UserContextValue = {
  emailVerified: boolean;
  uid: string;
};

export const UserContext = createContext<UserContextValue>({ emailVerified: true, uid: "" });

export function useUserContext() {
  return useContext(UserContext);
}
