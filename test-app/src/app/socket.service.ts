import { browser } from 'protractor';
import { Injectable } from '@angular/core';

declare const Phoenix: any;

@Injectable({
  providedIn: 'root'
})
export class SocketService {

  socket: any;
  channel: any;

  constructor() {
    this.socket = new Phoenix.Socket('ws://localhost:4000/socket', {
      logger: (kind, msg, data) => {
        console.log(`${kind}: ${msg}`, data);
      },
      transport: WebSocket
    });
    this.socket.connect();

    this.channel = this.socket.channel('room:admin', {});
    //this.channel = this.socket.channel('room:admin', {params: {user: 'test'}});

    this.channel
      .join()
      .receive('ok', resp => {
        console.log('Joined successfully', resp);
      })
      .receive('error', resp => {
        console.log('Unable to join', resp);
      });

    this.channel.on('from_client_to_admin', payload => {
      console.log('received : ', payload);
        if (payload.body.transport_pid) {
          this.channel.push('msg_from_admin', { body: {data: "hello from admin", to: payload.body.transport_pid} });
        }
    });

    this.channel.push('msg_from_admin', { body: 'test' });
  }
}
