import { createContext, useContext } from "react";

type UserContextValue = {
  emailVerified: boolean;
};

export const UserContext = createContext<UserContextValue>({ emailVerified: true });

export function useUserContext() {
  return useContext(UserContext);
}
